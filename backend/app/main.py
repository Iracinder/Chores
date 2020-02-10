import datetime
import json
import os
from pathlib import Path

from fastapi import FastAPI
from starlette.responses import RedirectResponse

app = FastAPI()

CHORES_FILE = Path(os.environ.get('CHORES_JSON', 'app/chores.json'))


def get_chore_conf():
    return json.loads(CHORES_FILE.read_text())


def convert(element):
    try:
        timestamp = datetime.datetime.strptime(element, '%Y-%m-%d %H:%M:%S.%f')
        return int(timestamp.timestamp()) * 1000
    except (ValueError, TypeError):
        return element


@app.get('/')
def redirect():
    return RedirectResponse(url='/docs')


@app.get('/chores/list')
def get_chores():
    chores_json = {chore_name: {parameter: convert(value)
                                for parameter, value in settings.items()}
                   for chore_name, settings in get_chore_conf().items()}
    return chores_json


@app.post('/chores/<chore_name>')
def reset_chore(chore_name):
    chores_json = get_chore_conf()
    chores_json[chore_name]['start_time'] = str(datetime.datetime.now())
    CHORES_FILE.write_text(json.dumps(chores_json, indent=2))
    return 'Success'
