# README

Archyve is a web app that makes pretrained LLMs aware of a user's documents, while keeping those documents on the user's own devices and infrastructure.

<img src="app/assets/images/archyve_font.svg" width=100>

## Overview

Archyve enables Retrieval-Augmented Generation (RAG) by providing an API to query the user's docs for relevant context. The client provides the prompt the user gave, and Archyve will return relevant text chunks.

Archyve provides:

- a document upload and indexing UI, where the user can upload documents and test similarity searches against them
- a built-in LLM chat UI, so the user can test the effectiveness of their documents with an LLM
- an API, so the user can provide Archyve search results in dedicated LLM chat UIs

## Getting started

To run Archyve, use `docker compose` or `podman compose`.

1. Clone this repo
2. `cp dotenv_template local.env`
3. Run `openssl rand -hex 64` and put the value in the `SECRET_KEY_BASE` variable in your `local.env` file
4. Run the container

```bash
docker compose up --build
```

> If you see "✘ archyve-worker Error", don't worry about it. Docker will build the image and run it.

5. get a shell in the Archyve container with `docker compose exec archyve bash`
6. run `bin/rails db:encryption:init` from within the container:

```bash
$ rails db:encryption:init
Running `bin/rails db:encryption:init` in environment 'dev'...
Add this entry to the credentials of the target environment:

active_record_encryption:
  primary_key: PqxwHUF2E3MnPUW3qmOHUikIWJxhvY90
  deterministic_key: wJi0qI8KftvGhqkNh42SaG2oh64ZKIGZ
  key_derivation_salt: sE2nd5xn1rq2YdkDHHxQOuDhcOMfV5jr
```

7. put the values from the output into your `local.env` file

```bash
...
ACTIVE_RECORD_ENCRYPTION="{
  \"primary_key\": \"PqxwHUF2E3MnPUW3qmOHUikIWJxhvY90\",
  \"deterministic_key\": \"wJi0qI8KftvGhqkNh42SaG2oh64ZKIGZ\",
  \"key_derivation_salt\": \"sE2nd5xn1rq2YdkDHHxQOuDhcOMfV5jr\"
}"
```

8. Restart the containers
9. Browse to http://127.0.0.1:3300 and log in with `admin@archyve.io` / `password` (you can change these values by setting `USERNAME` and `PASSWORD` in your `local.env` file and restarting the container)

## API

Archyve provides a ReST API. To use it, you must have:

1. a Client ID (goes in the `X-Client-Id` header in all API requests)
2. an API key (goes in the `Authorization` header after `Bearer `)

> TODO: add this to the UI

To get these values:

1. ensure you have set up `ACTIVE_RECORD_ENCRYPTION` as described above
2. run `docker compose exec archyve sh`
3. from the shell inside the container, run `bin/rails c`
4. from the Rails console, run this code:

```ruby
Client.create!(name: "default", client_id: Client.new_client_id, api_key: Client.new_api_key, user: User.first)
"Client ID: #{Client.first.client_id}"
"API Key:   #{Client.first.api_key}"
```

5. copy the values into your `local.env` file and restart the container

You should be able to send API requests like this:

```sh
curl -v localhost:3300/v1/collections \
  -H "Accept: application/json" \
  -H "Authorization: Bearer <YOUR_API_KEY>" \
  -H "X-Client-Id: <YOUR_CLIENT_ID>"
```

See [archyve.io](https://archyve.io) for more information on the API.

See the next section for setting up Ollama for use by Archyve or **document uploads and chat will fail**.

## Dependencies

### Ollama

> You can run a dedicated instance of Ollama in a container by adding it to the `compose.yaml` file, but it takes a while to pull a chat model, so the default here is to assume you already have an Ollama instance.

Archyve will use a local instance of [Ollama](https://ollama.com/) by default. Ensure you have Ollama installed and running (with `ollama serve`) and then run the following commands to set up your Ollama instance for Archyve:

- fast embedding model: `ollama pull all-minilm`
- better embedding model: `ollama pull nomic-embed-text`
- chat model: `ollama pull mistral:instruct`
- alternative chat model: `ollama pull gemma:7b` (if you intend to use Gemma)

### Embedding models

You can select an embedding model separately for each Collection you create inside Archyve.

To make an embedding model available for use in Archyve, go to the ModelConfig page in the [admin UI](http://127.0.0.1:3300/admin), create a new ModelConfig, and set `embedding` to `true`. The new embedding model should be an option when creating a Collection, or viewing a Collection which has no Documents in it.

Make sure you pull the model in Ollama.

### Summarization model

You can change summarization model by changing `SUMMARIZATION_ENDPOINT` and `SUMMARIZATION_MODEL` in your `local.env` file and restarting the server. If you change these values, make sure the new models are present in Ollama.

## Admin UI

There is an admin UI running at http://127.0.0.1:3300/admin. There, you can view and change ModelConfigs and ModelServers if you are logged in as an admin.

There is a link to it in the bottom of the side bar.

## Jobs

Archyve uses a jobs framework called Sidekiq. It has a web UI that you can access at http://127.0.0.1/sidekiq if you are logged in as an admin.
