<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://swetrix.com/assets/logo_white.png">
  <img alt="" src="https://swetrix.com/assets/logo_blue.png" width="360">
</picture>
<br /><br />

## What is Swetrix?

[Swetrix](https://swetrix.com) is a fully open source, privacy focused and cookieless alternative to Google Analytics. Swetrix aims to be a lightweight tool (tracking script is < 5 KB), yet powerful enough to give you all the insights you need. With Swetrix you can track your site's traffic, monitor your site's speed, analyse user sessions and pageflows, see the user flows and much more! All of it without invading your user's privacy. Check out our [live demo](https://swetrix.com/projects/STEzHcB1rALV).

## How to selfhost?

> [!NOTE]
> The guide below explains how to get started quickly with the self-hosted version of Swetrix. What you're probably looking for is a more in-depth and step-by-step guide, which can be found on our [self-hosted documentation page](https://docs.swetrix.com/selfhosting/how-to).

So, to self-host Swetrix, you need to:
1. Clone this repository:
```bash
git clone https://github.com/swetrix/selfhosting
cd selfhosting
```
2. [Install Docker](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04?ref=swetrix.com) if you haven't already.
3. Configure the environment variables for your Swetrix instance. It can be easily done by running `./configure.sh` script, which will ask you to provide the necessary values (including `BASE_URL`) and generate a `.env` file with them. See the [configuration variable reference](https://docs.swetrix.com/selfhosting/configuring).
4. Run `docker compose up -d` to start the Swetrix services.
5. After that, you will be able to access Swetrix web portal at the URL you set in `BASE_URL` (by default, `http://localhost`).

And that's it! :) If you have any questions, feel free to join our [Discord community](https://discord.gg/ZVK8Tw2E8j). You can also star our [main repository](https://github.com/Swetrix/swetrix) as a token of appreciation.

## Session replays

Community Edition supports session recording, playback, and MP4 exports with your own private S3-compatible bucket. Use matching API and frontend release versions that include CE session replay support.

Create a private bucket and credentials with permission to read, write, and delete its objects. Add the storage settings to your `.env`, for example with AWS S3:

```dotenv
SESSION_REPLAY_S3_ENDPOINT=https://s3.eu-west-1.amazonaws.com
SESSION_REPLAY_S3_BUCKET=swetrix-replays
SESSION_REPLAY_S3_REGION=eu-west-1
SESSION_REPLAY_S3_ACCESS_KEY_ID=your-access-key
SESSION_REPLAY_S3_SECRET_ACCESS_KEY=your-secret-key
SESSION_REPLAY_S3_FORCE_PATH_STYLE=false
```

Use the S3 API endpoint without the bucket name or an object path. For MinIO, use a reachable API endpoint such as `http://minio:9000`, region `us-east-1`, and `SESSION_REPLAY_S3_FORCE_PATH_STYLE=true`. For Cloudflare R2, use `https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com`, region `auto`, and path style `true`. For Hetzner, the region is inferred from its location endpoint when left blank.

Compose forwards these variables to the API container. The generated and example environment files include optional replay settings; existing installations can add them manually. Keep credentials on the server. The bucket does not need public access or browser CORS rules, and ordinary analytics works without replay storage.

When upgrading an existing installation, follow the [release notes](https://github.com/Swetrix/swetrix/releases) for any required migrations and upgrade steps.

After changing the replay configuration, recreate the API, frontend and Nginx containers:

```bash
docker compose up -d --force-recreate swetrix-api swetrix nginx-proxy
```

The included Nginx configuration allows replay uploads up to 15 MiB. Apply the same upload limit to any additional reverse proxy in front of Swetrix.

Start recording explicitly from your website after initialising a current Swetrix tracker:

```javascript
swetrix.init("YOUR_PROJECT_ID", {
  apiURL: "https://analytics.example.com/backend",
});

await swetrix.startSessionReplay({ privacy: "total" });
```

Watch recordings in the project's **Replays** tab. Retention defaults to 30 days and can be changed to 90 days, 1 year, or 5 years in **Project Settings > Session replays**. Keep the primary API node running for expiry cleanup, and back up both ClickHouse and the bucket.

MP4 exports run on the API server with a default concurrency of `1`. `SESSION_REPLAY_EXPORT_CONCURRENCY` controls parallel renders, and `SESSION_REPLAY_EXPORT_TTL_SECONDS` controls how long generated MP4 files remain available (default: 24 hours). Allow additional CPU, RAM, and temporary disk space for exports.

See the [session replay setup guide](https://swetrix.com/docs/selfhosting/session-replays) for storage permissions, retention, privacy settings, and troubleshooting.
