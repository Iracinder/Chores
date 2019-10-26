from flask import Flask, jsonify
from pathlib import Path
import os
import json
import datetime

app = Flask(__name__)

CHORES_FILE = Path(os.environ.get('CHORES_JSON', 'chores.json'))


def get_chore_conf():
    return json.loads(CHORES_FILE.read_text())


def convert(element):
    try:
        timestamp = datetime.datetime.strptime(element, '%Y-%m-%d %H:%M:%S.%f')
        return int(timestamp.timestamp()) * 1000
    except (ValueError, TypeError):
        return element


@app.route('/chores')
def get_chores():
    chores_json = {chore_name: {parameter: convert(value)
                                for parameter, value in settings.items()}
                   for chore_name, settings in get_chore_conf().items()}
    response = jsonify(chores_json)
    response.headers.add('Access-Control-Allow-Origin', '*')
    return response


@app.route('/chores/<chore_name>', methods=['POST'])
def reset_chore(chore_name):
    chores_json = get_chore_conf()
    chores_json[chore_name]['start_time'] = str(datetime.datetime.now())
    CHORES_FILE.write_text(json.dumps(chores_json, indent=2))
    return 'Success'


if __name__ == '__main__':
    app.run()
