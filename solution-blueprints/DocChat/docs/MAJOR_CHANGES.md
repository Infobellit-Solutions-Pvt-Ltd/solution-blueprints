# Major Changes in DocChat Compared to talk-to-your-documents

This document summarizes the major changes introduced in `DocChat` relative to `talk-to-your-documents`.

## Summary

`DocChat` keeps the same overall RAG pattern as the original app: a FastAPI + Gradio frontend/backend, an embedding service, and an LLM used to answer questions over uploaded documents. The main changes are in the storage layer, document handling, deployment model, and operational tooling.

## 1. Vector Database Changed from ChromaDB to Qdrant

The largest architectural change is the replacement of **ChromaDB** with **Qdrant**.

- `talk-to-your-documents` used `chromadb` and `langchain-chroma`.
- `DocChat` uses `qdrant-client` and `langchain-qdrant`.
- Runtime configuration changed from `CHROMADB_URL/HOST/PORT` to `QDRANT_URL/HOST/PORT`.
- Helm chart dependencies were updated to remove the ChromaDB subchart, and `DocChat` now defines its own Qdrant deployment templates.

Why this matters:

- Qdrant is now the default vector store for indexing and retrieval.
- The chart can target either a bundled in-cluster Qdrant instance or an external Qdrant endpoint.
- Qdrant is treated as a first-class deployment component rather than just a drop-in backend swap.

## 2. Document Sources Are Tracked and Exposed

`DocChat` adds explicit tracking of indexed document sources.

- During indexing, document metadata now stores both `source` and `source_name`.
- The backend can enumerate indexed documents from Qdrant.
- The app can resolve a document name back to its stored source.
- New API routes were added:
  - `GET /documents`
  - `GET /documents/{document_name}`

Why this matters:

- The original app focused on upload-and-ask behavior only.
- `DocChat` adds a document inventory layer on top of retrieval.
- Indexed files are now discoverable and can be fetched back through the app.

## 3. UI Adds Indexed Document Browsing and Preview

The Gradio UI is extended beyond simple upload + question answering.

- A dropdown lists indexed documents already known to the system.
- A refresh action reloads the indexed document list.
- The UI shows selected-document status.
- PDF files can be previewed inline in an iframe.
- Text files can be previewed inline in a formatted text block.
- Clearing the app now resets document-selection state as well as question/answer state.

Why this matters:

- `DocChat` behaves more like a document workspace than a one-shot upload form.
- Users can inspect what has already been indexed before asking questions.
- The app now supports a lightweight review workflow for stored source files.

## 4. Optional Source Storage via MinIO / S3

`DocChat` introduces optional object-storage support for original source documents.

- New config keys exist for `MINIO_ENABLED`, endpoint, credentials, bucket, region, and prefix.
- When enabled, uploaded source files can be copied into MinIO/S3-compatible storage before indexing.
- Document fetch operations can read back file contents either from local pod storage or from MinIO.

Why this matters:

- The original app only indexed local files for retrieval.
- `DocChat` adds a path toward durable source-file management, not just vector storage.
- This makes document preview/download features possible even when the app pod is not the long-term source of truth.

## 5. Deployment Workflow Became Much More Operationally Focused

`DocChat` significantly expands deployment and bootstrap automation.

- New scripts were added:
  - `deploy.sh`
  - `cleanup_redeploy.sh`
  - `clean.sh`
  - `run.sh`
  - `generate_configure_tls_cert.sh`
- The deployment flow now supports:
  - syncing documents from an ONTAP FlexCache mount over SSH/`rsync`
  - copying staged documents into the app pod
  - automatically calling the app’s `/process` API to pre-index those documents
  - optional local model-cache host mounts
  - automatic namespace and Hugging Face secret setup

Why this matters:

- The original blueprint was a relatively simple Helm deployment.
- `DocChat` is closer to an end-to-end deploy-and-bootstrap system.
- The app is designed for preloaded enterprise document sources, not just manual uploads from the browser.

## 6. Helm Chart Was Reworked for Enterprise Routing and Service Control

The Kubernetes packaging is more elaborate in `DocChat`.

- `service` settings are now configurable in `values.yaml` instead of fixed.
- A new `HTTPRoute` exposes the app through Gateway API.
- A separate `qdrant-httproute.yaml` can expose Qdrant through the gateway when needed.
- `qdrant.yaml` adds bundled Qdrant `Service`, `Deployment`, and `PersistentVolumeClaim`.
- Init-container readiness checks were changed to wait for Qdrant instead of ChromaDB.
- Values were added for external Qdrant usage, fallback Qdrant behavior, and gateway hostnames.

Why this matters:

- `DocChat` is built for a more production-style Kubernetes environment.
- External access is now part of the default design through `kgateway`/Gateway API.
- Storage and service exposure are more configurable than in the original app.

## 7. LLM Packaging and Runtime Configuration Were Expanded

`DocChat` also makes LLM deployment more flexible.

- The chart now points to a local `charts/aimchart-llm-local` dependency instead of the previous OCI LLM chart reference.
- New values support GPU count overrides and local model-cache mounts.
- `GEN_MODEL` is explicitly configurable in `values.yaml`.
- `EMBED_MODEL` and `GEN_MODEL` can now be overridden directly from environment variables instead of always being discovered dynamically at startup.

Why this matters:

- The modified app is easier to tune for specific hardware and model-cache layouts.
- It is better suited for controlled deployments where model identity is known ahead of time.

## 8. Documentation Was Expanded from Basic Helm Notes to Full Deployment Guides

`DocChat` adds much more operational documentation.

- New documents describe architecture and deployment end-to-end.
- The old short Helm deployment notes were replaced by a canonical deployment guide.
- A build guide was added for AMD AIMs, Qdrant, FlexCache, SSH setup, TLS, and verification.
- New diagrams and Mermaid sources were added for architecture/deployment flow.

Why this matters:

- `DocChat` is documented as a full solution deployment, not just a reusable sample chart.
- The documentation reflects real infrastructure assumptions and bootstrap steps.

## Overall Assessment

Compared to `talk-to-your-documents`, `DocChat` is not just a rename or a small customization. It is a more opinionated enterprise-oriented variant with:

- a new vector database stack based on Qdrant
- document catalog and preview capabilities
- optional object storage for source files
- stronger Kubernetes routing and persistence support
- deployment automation for FlexCache-based document ingestion
- more explicit model and infrastructure configuration

In short, `talk-to-your-documents` is a simpler RAG blueprint, while `DocChat` turns that blueprint into a more complete document-chat deployment platform.
