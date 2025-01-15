up:
	docker run -it --rm --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n

down:
	docker stop n8n 

logs:
	docker n8n logs -f

create_vol:
	docker volume create n8n_data