#!/usr/bin/env python3

import argparse
import asyncio
import logging
import json
import urllib.parse
from aiohttp import ClientSession

logging.basicConfig(level=logging.INFO)


args = argparse.ArgumentParser()
args.add_argument(
    "--api-key",
    type=str,
    required=True,
    help="NextDNS API key file",
    metavar="api_key",
)
args.add_argument(
    "--json-hosts-file",
    type=argparse.FileType("r"),
    required=True,
    help="JSON hosts file",
    metavar="hosts_file",
)
args.add_argument(
    "--home-profile", type=str, help="NextDNS ID of the Home profile", required=True
)
args.add_argument(
    "--tailscale-profile",
    type=str,
    help="NextDNS ID of the Tailscale profile",
    required=True,
)

args = args.parse_args()

API_ENDPOINT = "https://api.nextdns.io/"

API_KEY = args.api_key

with open(args.json_hosts_file.name) as hosts_file:
    HOSTS: [dict] = json.load(hosts_file)
logging.debug(f"Loaded {len(HOSTS)} hosts: {HOSTS=}")

home_rewrites = {
    host["domain"]: {"name": host["domain"], "content": host["home"]}
    for host in HOSTS
    if "home" in host
}
tailscale_rewrites = {
    host["domain"]: {"name": host["domain"], "content": host["ts"]}
    for host in HOSTS
    if "ts" in host
}


async def get_rewrites(session, profile_id) -> dict:
    url = urllib.parse.urljoin(API_ENDPOINT, f"/profiles/{profile_id}/rewrites")
    logging.debug(f"{url=}")
    async with session.get(url, headers={"X-Api-Key": API_KEY}) as response:
        return await response.json()


async def manage_rewrites(session, profile_id, current_rewrites, target_rewrites):
    # add new rewrites
    existing_rewrites = set(current_rewrites.keys())
    expected_rewrites = set(target_rewrites.keys())
    new_rewrites = expected_rewrites - existing_rewrites
    deleted_rewrites = existing_rewrites - expected_rewrites

    # add new rewrites
    url = urllib.parse.urljoin(API_ENDPOINT, f"/profiles/{profile_id}/rewrites")
    for domain in new_rewrites:
        logging.info(
            f"Adding rewrite for {domain} as {target_rewrites[domain]['content']} to profile {profile_id}"
        )
        async with session.post(
            url,
            headers={"X-Api-Key": API_KEY},
            json=target_rewrites[domain],
        ) as response:
            logging.debug(await response.json())
            logging.info(f"{response.ok=}")
    # delete old rewrites
    for domain in deleted_rewrites:
        url = urllib.parse.urljoin(
            API_ENDPOINT,
            f"/profiles/{profile_id}/rewrites/{current_rewrites[domain]['id']}",
        )
        logging.info(f"Deleting rewrite for {domain} from profile {profile_id}")
        async with session.delete(url, headers={"X-Api-Key": API_KEY}) as response:
            logging.info(f"{response.ok=}")

    # update existing rewrites
    for domain in existing_rewrites & expected_rewrites:
        if current_rewrites[domain]["content"] == target_rewrites[domain]["content"]:
            continue
        url = urllib.parse.urljoin(
            API_ENDPOINT,
            f"/profiles/{profile_id}/rewrites/{current_rewrites[domain]['id']}",
        )
        logging.debug(f"{url=}")
        logging.debug(f"{current_rewrites[domain]=}")
        logging.debug(f"{target_rewrites[domain]=}")
        logging.info(
            f"Updating rewrite for {domain} from {current_rewrites[domain]['content']} to {target_rewrites[domain]['content']} in profile {profile_id}"
        )
        async with session.delete(
            url,
            headers={"X-Api-Key": API_KEY},
        ) as response:
            logging.info(f"Deletion status: {response.ok=}")
            if not response.ok:
                logging.error(await response.json())
                continue
        async with session.post(
            urllib.parse.urljoin(API_ENDPOINT, f"/profiles/{profile_id}/rewrites"),
            headers={"X-Api-Key": API_KEY},
            json=target_rewrites[domain],
        ) as response:
            logging.info(f"Update status: {response.ok=}")
            if not response.ok:
                logging.error(await response.json())
                continue
        logging.info("Updated rewrite")

    if combined := (existing_rewrites & expected_rewrites):
        logging.debug(combined)


async def main(loop):
    async with ClientSession(loop=loop) as websession:
        for profile_id, target_rewrites in [
            (args.home_profile, home_rewrites),
            (args.tailscale_profile, tailscale_rewrites),
        ]:
            current_rewrites = await get_rewrites(websession, profile_id)
            current_rewrites = {
                rewrite["name"]: rewrite for rewrite in current_rewrites["data"]
            }
            await manage_rewrites(
                websession, profile_id, current_rewrites, target_rewrites
            )


loop = asyncio.new_event_loop()
loop.run_until_complete(main(loop))
loop.close()
