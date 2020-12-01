package manager

import (
	"net/http"

	"github.com/emicklei/go-restful"
	restfulspec "github.com/emicklei/go-restful-openapi"

	"gopkg.in/logex.v1"
)

// WebService creates a new service that can handle REST requests for User resources.
func (mgr *Manager) WebService() *restful.WebService {
	ws := new(restful.WebService)
	ws.Path("/api/v1").Consumes(restful.MIME_JSON).Produces(restful.MIME_JSON) // you can specify this per route as well

	//	Consumes(restful.MIME_JSON, restful.MIME_XML).Produces(restful.MIME_JSON, restful.MIME_XML)

	tags := []string{"SecGroup(firewall)"}

	ws.Route(ws.GET("/").To(func(request *restful.Request, response *restful.Response) {
		result := map[string]string{
			"/a":      "GET POST DELETE",
			"/a/<id>": "GET PUT DELETE",
			"/b-<id>": "GET PUT DELETE",
			"/c-<id>": "GET PUT DELETE",
		}
		response.WriteEntity(result)
	}).
		// docs
		Doc("Request server with its agent configured.").
		Metadata(restfulspec.KeyOpenAPITags, tags).
		Writes(map[string]string{}).
		Returns(200, "OK", map[string]string{}).
		Returns(404, "Not found", nil))

	/*
	   $ curl -X POST -H "Content-Type: application/json" http://localhost:2375/api/v1/secgroups \
	   -d '["sudo iptables -a INPUT -j secgroups", "sudo iptables -i enp0s8 -s 172.18.0.0/24 -j ACCEPT"]' -iv
	*/
	ws.Route(ws.POST("/secgroups/").To(func(request *restful.Request, response *restful.Response) {
		rules := make([]string, 0)
		if err := request.ReadEntity(&rules); err != nil {
			response.WriteError(http.StatusBadRequest, err)
		} else if len(rules) == 0 {
			response.WriteHeader(http.StatusNoContent)
		} else {
			logex.Pretty(rules)
			if err := mgr.UpdateRules(rules); err != nil {
				response.WriteError(http.StatusInternalServerError, err)
			} else {
				response.WriteHeader(http.StatusOK)
				// response.WriteHeader(http.StatusAccepted)
				// response.WriteHeader(http.StatusCreated)
			}
		}
	}).
		// docs
		Doc("Request server to configure security group rules").
		Param(ws.BodyParameter("rules", "security group rules").DataType("object")).
		Metadata(restfulspec.KeyOpenAPITags, tags).
		Returns(200, "OK", nil).
		Returns(201, "Created", nil).
		Returns(202, "Accepted", nil).
		Returns(204, "No content", nil).
		Returns(400, "Bad request", nil).
		Returns(403, "Forbidden, request not identified", nil).
		Returns(500, "Internal server error, unexpected to get", nil))

	//	ws.Route(ws.POST("/servers").To(func(request *restful.Request, response *restful.Response) {
	//		var server apitypes.Server
	//		if err := request.ReadEntity(&server); err != nil {
	//			response.WriteError(http.StatusInternalServerError, fmt.Errorf("Add server error: %s", err))
	//			return
	//		}
	//		if err := mgr.AddServer(server); err != nil {
	//			response.WriteError(http.StatusInternalServerError, err)
	//			return
	//		}
	//		response.WriteHeader(http.StatusCreated)
	//	}).
	//		// docs
	//		Doc("Request new server for Kubernetes takeoff").
	//		Metadata(restfulspec.KeyOpenAPITags, tags).
	//		Reads(apitypes.Server{}).
	//		Returns(200, "OK", nil).
	//		Returns(201, "Created", nil).
	//		Returns(403, "Forbidden, request not identified", nil).        // from the request
	//		Returns(404, "Not found", nil).
	//		Returns(500, "Internal server error, unexpected to set", nil)) // from the request

	//	ws.Route(ws.GET("/agents/{agent-id}/networks").To(func(request *restful.Request, response *restful.Response) {
	//		argID := request.PathParameter("agent-id")
	//		result, err := dispatch.GetKubernetesNodeNetworking(argID)
	//		if err != nil {
	//			response.WriteError(http.StatusInternalServerError, err)
	//			return
	//		}
	//		response.WriteEntity(result)
	//	}).
	//		// docs
	//		Doc("Request a virtual sub-system like docker container resource spec").
	//		Param(ws.PathParameter("agent-id", "The identifier of this agent").
	//			DataType("string").
	//			DefaultValue("required")).
	//		Metadata(restfulspec.KeyOpenAPITags, tags).
	//		Writes(collectapi.KubernetesNodeNetworkingAgentModel{}).
	//		Returns(200, "OK", collectapi.KubernetesNodeNetworkingAgentModel{}).
	//		Returns(403, "Forbidden, request not identified", nil).             // from the request
	//		Returns(500, "Internal server error, unexpected to get spec", nil)) // from the request

	//	ws.Route(ws.GET("/{agent-id}/stats").To(dispatch.reapStats).
	//		// docs
	//		Doc("Request all statistcs from machine").
	//		Param(ws.PathParameter("agent-id", "agent id, unique to one machine").
	//			DataType("string").
	//			DefaultValue("required")).
	//		Metadata(restfulspec.KeyOpenAPITags, tags).
	//		Writes(map[string]collectapi.ContainerInfo{}). // on the response
	//		Returns(200, "OK", map[string]collectapi.ContainerInfo{}).
	//		Returns(403, "Forbidden, request not identified", nil). // from the request
	//		Returns(500, "Internal server error, unexpected to reap networking", nil))

	//	ws.Route(ws.GET("/{agent-id}/events").To(dispatch.reapEvents).
	//		// docs
	//		Doc("Request container life and its network state events").
	//		Param(ws.PathParameter("agent-id", "agent id, unique to one machine").
	//			DataType("string").
	//			DefaultValue("required")).
	//		Metadata(restfulspec.KeyOpenAPITags, tags).
	//		Writes([]*collectapi.Event{}). // on the response
	//		Returns(200, "OK", []*collectapi.Event{}).
	//		Returns(403, "Forbidden, request not identified", nil). // from the request
	//		Returns(500, "Internal server error, unexpected to reap networking", nil))

	//	ws.Route(ws.GET("/{agent-id}/docker-images/{image-id}").
	//		To(dispatch.getDockerImageLayersFs).
	//		// docs
	//		Doc("Request docker image layers and filesys tree").
	//		Param(ws.PathParameter("agent-id", "The identifier of this agent").
	//			DataType("string").
	//			DefaultValue("required")).
	//		Param(ws.PathParameter("image-id", "The docker image id").
	//			DataType("string").
	//			DefaultValue("for example: docker.io/nginx:latest")).
	//		Metadata(restfulspec.KeyOpenAPITags, tags).
	//		Writes(apidockerinfo.DockerImageLayersFs{}).
	//		Returns(200, "OK", apidockerinfo.DockerImageLayersFs{}).
	//		Returns(403, "Forbidden, required agent id", nil).              // from the request
	//		Returns(500, "Internal Server Error, unexpected to reap", nil)) // from the request

	//	ws.Route(ws.GET("/{agent-id}/cadvisor-machineinfo").
	//		To(dispatch.reapCAdvisorMachineInfo).
	//		// docs
	//		Doc("Request machine info according Google cAdvisor").
	//		Param(ws.PathParameter("agent-id", "The identifier of this agent").DataType("string").
	//			DataType("string")).
	//		Metadata(restfulspec.KeyOpenAPITags, tags).
	//		Writes(info.MachineInfo{}).
	//		Returns(200, "OK", info.MachineInfo{}).
	//		Returns(404, "Not Found", nil)) // from the request

	//	ws.Route(ws.GET("/{agent-id}/cadvisor-cgroups").
	//		To(dispatch.reapCAdvisorCgroups).
	//		// docs
	//		Doc("Request cgroups according Google cAdvisor").
	//		Param(ws.PathParameter("agent-id", "The identifier of this agent").DataType("string").
	//			DataType("string")).
	//		Metadata(restfulspec.KeyOpenAPITags, tags).
	//		Writes(info.ContainerInfo{}).
	//		Returns(200, "OK", info.ContainerInfo{}).
	//		Returns(404, "Not Found", nil)) // from the request

	//	ws.Route(ws.GET("/{agent-id}/cadvisor-cgroups/docker-containers").
	//		To(dispatch.reapCAdvisorDockerContainers).
	//		// docs
	//		Doc("Request docker containers according Google cAdvisor").
	//		Param(ws.PathParameter("agent-id", "The identifier of this agent").DataType("string").
	//			DataType("string")).
	//		Metadata(restfulspec.KeyOpenAPITags, tags).
	//		Writes(info.ContainerInfo{}).
	//		Returns(200, "OK", info.ContainerInfo{}).
	//		Returns(404, "Not Found", nil)) // from the request

	//	ws.Route(ws.GET("/{agent-id}/cadvisor-cgroups/docker-containers/{container-id}").
	//		To(dispatch.reapCAdvisorDockerContainerInfo).
	//		// docs
	//		Doc("Request docker container info according Google cAdvisor").
	//		Param(ws.PathParameter("agent-id", "The identifier of this agent").
	//			DataType("string")).
	//		Param(ws.PathParameter("container-id", "The docker container id").
	//			DataType("string")).
	//		Metadata(restfulspec.KeyOpenAPITags, tags).
	//		Writes(info.ContainerInfo{}).
	//		Returns(200, "OK", info.ContainerInfo{}).
	//		Returns(404, "Not Found", nil)) // from the request

	return ws
}
