FROM continuumio/miniconda3 as builder

ADD conda_env.yaml /
RUN conda env create -f conda_env.yaml

FROM builder
ADD scoring.py shutdown.py trained_pipe.pkl /

ENTRYPOINT ["conda", "run", "-n", "simonyi_workshop", "python", "scoring.py"]
