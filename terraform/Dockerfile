# FROM python:3.7.4-slim
FROM continuumio/miniconda3

WORKDIR /mlflow/

RUN mkdir -p /mlflow/ \
  && apt-get update && apt-get -y install postgresql postgresql-contrib gcc libpq-dev build-essential \
  && pip install \
    mlflow \
    sqlalchemy \
    boto3 \
    google-cloud-storage \
    psycopg2 \
    google-api-python-client \
    psycopg2-binary

EXPOSE 5000

ENV BACKEND_URI /mlflow/store
ENV ARTIFACT_ROOT /mlflow/mlflow-artifacts
ENV PORT 5000
CMD echo "Artifact Root is ${ARTIFACT_ROOT}" && \
  echo "Backend URI is ${BACKEND_URI}" && \
  mlflow server \
  --backend-store-uri ${BACKEND_URI} \
  --default-artifact-root ${ARTIFACT_ROOT} \
  --host 0.0.0.0 \
  --port ${PORT}