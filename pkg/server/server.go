package server

import (
	"context"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"google.golang.org/grpc"

	"gopkg.in/logex.v1"

	"github.com/tangfeixiong/nta/pkg/firewall"
	"github.com/tangfeixiong/nta/pkg/manager"
)

func MainFirewall(conf *firewall.Config) {
	agent := NewOrDie(conf)
	agent.Start()
}

type agentServer struct {
	config     *firewall.Config
	listener   net.Listener
	httpServer *http.Server
	grpcServer *grpc.Server

	manager *manager.Manager
}

//var _ Server = &agentServer{}

// Link
// - https://github.com/google/cadvisor/blob/master/cmd/cadvisor.go#L168
func NewOrDie(conf *firewall.Config) *agentServer {
	lstn, err := net.Listen("tcp", conf.ServerAddress)
	if err != nil {
		panic(err)
	}
	mgr, err := manager.NewOrErr()
	if err != nil {
		panic(err)
	}
	agents := &agentServer{
		config:   conf,
		listener: lstn,
		manager:  mgr,
	}
	return agents
}

func (agent *agentServer) Start() {
	defer func() {
		logex.Warn("Detected net closing")
		agent.listener.Close()
	}()

	//	tcpMux := cmux.New(agent.listener)
	// We first match the connection against HTTP2 fields. If matched, the
	// connection will be sent through the "grpcl" listener.
	//	grpcL := tcpMux.Match(cmux.HTTP2HeaderFieldPrefix("content-type", "application/grpc"))
	//Otherwise, we match it againts a websocket upgrade request.
	//	wsL := tcpMux.Match(cmux.HTTP1HeaderField("Upgrade", "websocket"))
	// Otherwise, we match it againts HTTP1 methods. If matched,
	// it is sent through the "httpl" listener.
	//	httpL := tcpMux.Match(cmux.HTTP1Fast())

	httpL := agent.listener
	_, httpServer, err := launchHTTP(httpL, func(router *http.ServeMux) error {
		webs := agent.manager.WebServices()
		if err := serveReSTful(router, webs...); err != nil {
			return err
		}
		return nil
	}, map[string]string{
		//		"/wasm/": "/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/nta/wasm/",
	})
	if err != nil {
		logex.Fatal("Start HTTP server error:", err.Error())
	}
	agent.httpServer = httpServer

	//	gRPCManager := agent.gRPCServerManager()
	//	grpcServer, _ := gRPC(grpcL, gRPCManager)
	//	agent.grpcServer = grpcServer

	//Handle signals
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)
	//	go func() {
	logex.Infof("INFO: Received shutdown signal: %s", <-sigs)
	agent.shutdown()
	//	}()

	//	defer logex.Infof("TCP mux for HTTP and Websocket: %v", agent.config.endpoints)
	//	if err := tcpMux.Serve(); !strings.Contains(err.Error(), "use of closed network connection") {
	//		panic(err)
	//	} else if err != nil {
	//		logex.Errorf("TCP mux enter error: %v", err)
	//		return err
	//	} else {
	//		return nil
	//	}

	//	select {}
}

//func (agent *agentServer) gRPCServerManager() func(*grpc.Server) {
//	rpc := agent.manager
//	return func(gs *grpc.Server) {
//		pbxxx.RegisterXXXServiceServer(gs, rpc)
//	}
//}

func (agent *agentServer) shutdown() {
	//Shutdown
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), time.Second*2)
	defer shutdownCancel()

	grpcShutdown := make(chan struct{}, 1)
	if agent.grpcServer != nil {
		go func() {
			logex.Debug("graceful stop gRPC...")
			agent.grpcServer.GracefulStop()
			grpcShutdown <- struct{}{}
		}()
	}

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)
	select {
	case <-grpcShutdown:
		logex.Debug("Immediate exit")
		os.Exit(0)
	case <-shutdownCtx.Done():
		if agent.grpcServer != nil {
			logex.Debug("stop gRPC finally...")
			agent.grpcServer.Stop()
		}
	case <-sigs:
	}
}

func gRPC(grpcL net.Listener, hdlr func(*grpc.Server)) (*grpc.Server, error) {
	var opts []grpc.ServerOption
	//	if *tls {
	//		if *certFile == "" {
	//			*certFile = testdata.Path("server1.pem")
	//		}
	//		if *keyFile == "" {
	//			*keyFile = testdata.Path("server1.key")
	//		}
	//		creds, err := credentials.NewServerTLSFromFile(*certFile, *keyFile)
	//		if err != nil {
	//			log.Fatalf("Failed to generate credentials %v", err)
	//		}
	//		opts = []grpc.ServerOption{grpc.Creds(creds)}
	//	}

	grpcServer := grpc.NewServer(opts...)
	//	pbxxx.RegisterXXXServiceServer(grpcServer, agent.grpcServiceControl())
	hdlr(grpcServer)

	go func() {
		if err := grpcServer.Serve(grpcL); err != /* cmux.ErrListenerClosed */ nil {
			logex.Infof("gRPC server unexpect to shutdown: %v", err)
		}
	}()
	defer logex.Infof("Starting gRPC service routine onto %s\n", grpcL.Addr().String())

	return grpcServer, nil
}

func launchHTTP(httpL net.Listener, wsHdlr func(*http.ServeMux) error, fsHdlrs map[string]string) (*http.ServeMux, *http.Server, error) {

	router := http.NewServeMux()
	//	router.HandleFunc("/swagger.json", func(w http.ResponseWriter, req *http.Request) {
	//		io.Copy(w, strings.NewReader(pb.Swagger))
	//	})
	//	serveSwagger(router)

	//	rs := agent.manager.WebService()
	//	if err := serveReSTful(router, rs); err != nil {
	//		panic(err)
	//	}
	if err := wsHdlr(router); err != nil {
		logex.Errorf("Web service launch error: %v", err)
		return router, nil, err
	}

	for path, fileName := range fsHdlrs {
		//		fileServer := http.FileServer(http.Dir("/Users/fanhongling/Downloads/workspace/src/github.com/tangfeixiong/go-to-kubernetes/wasm/collect/assets"))
		//		router.Handle("/wasm/", NoCache(http.StripPrefix("/wasm/", fileServer)))
		fileServer := http.FileServer(http.Dir(fileName))
		router.Handle(path, NoCache(http.StripPrefix("/wasm/", fileServer)))
	}

	// initialize grpc-gateway
	//	gw, err := newGateway(ctx, fmt.Sprintf("localhost:%s", port))
	//	if err != nil {
	//		panic(err)
	//	}
	//	router.Handle("/", gw)

	httpServer := &http.Server{
		//		Addr:    agent.endpoints,
		Handler:      router,
		ReadTimeout:  50 * time.Second,
		WriteTimeout: 100 * time.Second,
		IdleTimeout:  1200 * time.Second,
	}

	go func() {
		if err := httpServer.Serve(httpL); err != nil {
			logex.Warn("HTTP service routine unexpect to shutdown:", err)
		}
	}()
	defer logex.Infof("Starting HTTP service routine onto %s\n", httpL.Addr().String())

	return router, httpServer, nil
}

var epoch = time.Unix(0, 0).Format(time.RFC1123)

var noCacheHeaders = map[string]string{
	"Expires":         epoch,
	"Cache-Control":   "no-cache, private, max-age=0",
	"Pragma":          "no-cache",
	"X-Accel-Expires": "0",
}

var etagHeaders = []string{
	"ETag",
	"If-Modified-Since",
	"If-Match",
	"If-None-Match",
	"If-Range",
	"If-Unmodified-Since",
}

func NoCache(h http.Handler) http.Handler {
	fn := func(w http.ResponseWriter, r *http.Request) {
		// Delete any ETag headers that may have been set
		for _, v := range etagHeaders {
			if r.Header.Get(v) != "" {
				r.Header.Del(v)
			}
		}

		// Set our NoCache headers
		for k, v := range noCacheHeaders {
			w.Header().Set(k, v)
		}

		h.ServeHTTP(w, r)
	}

	return http.HandlerFunc(fn)
}
