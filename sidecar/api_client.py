"""
Submits a completed race to the Wreckfest 2 Race Log via the Supabase RPC endpoint.
"""

import requests


def submit_race(
    config: dict,
    track_slug: str,
    variation_slug: str,
    vehicle_name: str,
    place: int,
    lap_time_ms: int,
    total_time_ms: int,
    tuning: int,
) -> dict:
    """
    Call the insert_race_with_api_key RPC function on Supabase.
    Returns the parsed JSON response.
    """
    url = f"{config['supabase_url'].rstrip('/')}/rest/v1/rpc/insert_race_with_api_key"
    headers = {
        "apikey": config["supabase_anon_key"],
        "Content-Type": "application/json",
    }
    payload = {
        "p_api_key": config["api_key"],
        "p_track_slug": track_slug,
        "p_variation_slug": variation_slug,
        "p_vehicle_name": vehicle_name,
        "p_place": str(place),
        "p_lap_time_ms": lap_time_ms,
        "p_total_time_ms": total_time_ms,
        "p_tuning": tuning,
    }

    resp = requests.post(url, json=payload, headers=headers, timeout=10)
    resp.raise_for_status()
    return resp.json()
