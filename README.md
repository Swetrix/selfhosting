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
3. Configure the environment variables for your Swetrix instance. It can be easily done by running `./configure.sh` script, which will ask you to provide the necessary values and generate a `.env` file with them. A table explaining what each value means can be found [here](https://docs.swetrix.com/selfhosting/configuring).
4. Run `docker compose up -d` to start the Swetrix services.
5. After that, you will be able to access Swetrix web portal on the port you specified in `swetrix` category in `compose.yaml` (by default, it's set to `80`).

And that's it! :) If you have any questions, feel free to join our [Discord community](https://discord.gg/ZVK8Tw2E8j). You can also star our [main repository](https://github.com/Swetrix/swetrix) as a token of appreciation.
