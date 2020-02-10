FROM python:3.8

ARG BUILD_ENV
RUN pip install poetry
COPY poetry.lock pyproject.toml /

RUN poetry config virtualenvs.create false \
  && poetry install $(test "$BUILD_ENV" == production && echo "--no-dev") --no-interaction --no-ansi

EXPOSE 80

COPY ./app /app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
