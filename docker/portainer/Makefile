up:
	docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
	
down:
	docker rm -f portainer

agent_up:
	docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent

agent_down:
	docker rm -f portainer_agent

logs:
	docker logs -f portainer

logs_agent:
	docker logs -f portainer_agent
