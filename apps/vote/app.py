from flask import Flask, render_template, request, make_response
import os
import redis
import socket
import random
import json
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Get configuration from environment variables
redis_host = os.getenv('REDIS_HOST', 'redis')
redis_port = int(os.getenv('REDIS_PORT', '6379'))

# Options for voting
option_a = os.getenv('OPTION_A', 'Cats')
option_b = os.getenv('OPTION_B', 'Dogs')

# Connect to Redis
def get_redis():
    try:
        r = redis.Redis(host=redis_host, port=redis_port, socket_connect_timeout=2)
        r.ping()
        logger.info(f"Connected to Redis at {redis_host}:{redis_port}")
        return r
    except redis.ConnectionError as e:
        logger.error(f"Redis connection failed: {e}")
        return None

@app.route('/')
def index():
    voter_id = request.cookies.get('voter_id')
    if not voter_id:
        voter_id = hex(random.getrandbits(64))[2:-1]

    vote = None

    r = get_redis()
    if r:
        try:
            vote = r.get(voter_id)
            if vote:
                vote = vote.decode('utf-8')
        except Exception as e:
            logger.error(f"Error getting vote: {e}")

    resp = make_response(render_template(
        'index.html',
        option_a=option_a,
        option_b=option_b,
        hostname=socket.gethostname(),
        vote=vote,
    ))
    resp.set_cookie('voter_id', voter_id)
    return resp

@app.route('/vote', methods=['POST'])
def vote():
    voter_id = request.cookies.get('voter_id')
    if not voter_id:
        voter_id = hex(random.getrandbits(64))[2:-1]

    vote = request.form['vote']
    logger.info(f"Received vote for {vote} from voter {voter_id}")

    r = get_redis()
    if r:
        try:
            data = json.dumps({'voter_id': voter_id, 'vote': vote})
            r.rpush('votes', data)
            r.set(voter_id, vote)
            logger.info(f"Vote saved successfully")
        except Exception as e:
            logger.error(f"Error saving vote: {e}")

    resp = make_response(render_template(
        'index.html',
        option_a=option_a,
        option_b=option_b,
        hostname=socket.gethostname(),
        vote=vote,
    ))
    resp.set_cookie('voter_id', voter_id)
    return resp

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=False)
