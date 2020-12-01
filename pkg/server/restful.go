package server

import (
	"bytes"
	"fmt"
	"log"
	"net/http"
	"os"
	"runtime"

	"github.com/elazarl/go-bindata-assetfs"
	"github.com/emicklei/go-restful"
	restfulspec "github.com/emicklei/go-restful-openapi"
	"github.com/go-openapi/spec"

	"github.com/tangfeixiong/nta/pkg/ui/openapi"
)

func serveReSTful(mux *http.ServeMux, rs ...*restful.WebService) error {
	wsc := restful.NewContainer()
	wsc.ServeMux = mux
	//	wsc.DoNotRecover(true)
	wsc.RecoverHandler(logStackOnRecover)
	wsc.ServiceErrorHandler(writeServiceError)
	//	wsc.Router(restful.CurlyRouter{})
	//	wsc.EnableContentEncoding(false)
	//	restful.DefaultContainer.Add(u.WebService())
	for _, elem := range rs {
		wsc.Add(elem)
	}
	config := restfulspec.Config{
		// WebServices: restful.RegisteredWebServices(), // you control what services are visible
		WebServices: wsc.RegisteredWebServices(),
		APIPath:     "/apidocs.json",
		PostBuildSwaggerObjectHandler: /* enrichSwaggerObject */ func(swo *spec.Swagger) {
			swo.Info = &spec.Info{
				InfoProps: spec.InfoProps{
					Title:       "Cloud security agent",
					Description: "Interview cloud micro-segmentation with firewall and others",
					Contact: &spec.ContactInfo{
						Name:  "Feixiong Tang",
						Email: "tangfx128@gmail.com",
						URL:   "https://github.com/tangfeixiong",
					},
					License: &spec.License{
						Name: "APACHE",
						URL:  "http://www.apache.org/licenses/",
					},
					Version: "0.2.0",
				},
			}
			swo.Tags = []spec.Tag{spec.Tag{TagProps: spec.TagProps{
				Name:        "Cloud Security",
				Description: "Focus on OpenStack and its distribution"}},
				spec.Tag{TagProps: spec.TagProps{
					Name:        "SecGroup(firewall)",
					Description: "Supplied micro-segmentation with firewall "}}}
			swo.Schemes = []string{"http", "https"}
		},
	}
	//restful.DefaultContainer.Add(restfulspec.NewOpenAPIService(config))
	wsc.Add(restfulspec.NewOpenAPIService(config))

	// Optionally, you can install the Swagger Service which provides a nice Web UI on your REST API
	// You need to download the Swagger HTML5 assets and change the FilePath location in the config below.
	// Open http://localhost:8080/apidocs/?url=http://localhost:8080/apidocs.json
	//	http.Handle("/apidocs/", http.StripPrefix("/apidocs/", http.FileServer(http.Dir("/Users/emicklei/Projects/swagger-ui/dist"))))
	fileServer := http.FileServer(&assetfs.AssetFS{
		Asset:    openapi.Asset,
		AssetDir: openapi.AssetDir,
		Prefix:   "third_party/OpenAPI",
	})
	mux.Handle("/apidocs/", http.StripPrefix("/apidocs/", fileServer))

	// Optionally, you may need to enable CORS for the UI to work.
	cors := restful.CrossOriginResourceSharing{
		AllowedHeaders: []string{"Content-Type", "Accept"},
		AllowedMethods: []string{"GET", "POST", "PUT", "DELETE"},
		CookiesAllowed: false,
		Container:/* restful.DefaultContainer */ wsc,
	}
	//	restful.DefaultContainer.Filter(cors.Filter)
	wsc.Filter(cors.Filter)

	//	log.Printf("Get the API using http://localhost:8080/apidocs.json")
	//	log.Printf("Open Swagger UI using http://localhost:8080/apidocs/?url=http://localhost:8080/apidocs.json")
	logger := log.New(os.Stderr, "[init ReSTful] ", log.LstdFlags|log.Lshortfile)
	logger.Printf("Get the API using http://<host>/apidocs.json")
	logger.Printf("Open OpenAPI UI using http://<host>/apidocs/?url=http://<host>/apidocs.json")

	return nil
}

// logStackOnRecover is the default RecoverHandleFunction and is called
// when DoNotRecover is false and the recoverHandleFunc is not set for the container.
// Default implementation logs the stacktrace and writes the stacktrace on the response.
// This may be a security issue as it exposes sourcecode information.
func logStackOnRecover(panicReason interface{}, httpWriter http.ResponseWriter) {
	var buffer bytes.Buffer
	buffer.WriteString(fmt.Sprintf("recover from panic situation: - %v\r\n", panicReason))
	for i := 2; ; i += 1 {
		_, file, line, ok := runtime.Caller(i)
		if !ok {
			break
		}
		buffer.WriteString(fmt.Sprintf("    %s:%d\r\n", file, line))
	}
	//	log.Print(buffer.String())
	logger := log.New(os.Stderr, "[server2 logStackOnRecover] ", log.LstdFlags|log.Lshortfile)
	logger.Print(buffer.String())
	httpWriter.WriteHeader(http.StatusInternalServerError)
	httpWriter.Write(buffer.Bytes())
}

// writeServiceError is the default ServiceErrorHandleFunction and is called
// when a ServiceError is returned during route selection. Default implementation
// calls resp.WriteErrorString(err.Code, err.Message)
func writeServiceError(err restful.ServiceError, req *restful.Request, resp *restful.Response) {
	resp.WriteErrorString(err.Code, err.Message)
}
