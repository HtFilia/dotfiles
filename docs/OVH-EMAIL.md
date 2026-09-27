# Activate VPS health emails through OVH

This is the integration guide for the `homelab-infra` health checker. Dotfiles
provides the shell and Debian baseline; `homelab-infra` owns notification code,
its systemd unit and host-local mail settings. Run the commands below on the VPS
as your regular sudo-capable account. No password belongs in either repository.

## 1. Confirm the mailbox in OVH

1. Open the [OVHcloud Control Panel](https://www.ovh.com/manager/), select
   **Web Cloud → MX Plan**, and select your domain's mail service.
2. Under **General information**, check the **Webmail** technology. MX Plan can
   use Roundcube, Zimbra or OWA. The webmail technology alone does not identify
   a separately purchased Zimbra or Exchange offer.
3. Open **Emails** (Roundcube) or **Email accounts** (Zimbra/OWA). Confirm your
   sending address is a real mailbox. A forwarding address alone cannot log
   into SMTP. Reuse an existing mailbox; do not recreate it. If absent, use
   **Create an email address** or **Add Account**, enter the desired account
   name, choose a mailbox password, and confirm.
4. Sign in to [OVH webmail](https://www.ovhcloud.com/en/mail/) with the full
   address and that mailbox password. Confirm that you can read its inbox.

These navigation and account steps follow
[OVH's MX Plan account guide](https://docs.ovhcloud.com/en/guides/web-cloud/email-and-collaborative-solutions/mx-plan/email-creation).

For an **MX Plan mailbox hosted in Europe**, use:

| Setting | Value |
| --- | --- |
| SMTP server | `smtp.mail.ovh.net` |
| Port and encryption | `465`, implicit TLS |
| SMTP username | Your complete mailbox address |
| SMTP password | The mailbox password used in webmail |
| From and To | That same mailbox address |

These are [OVH's published MX Plan settings](https://docs.ovhcloud.com/en/guides/web-cloud/email-and-collaborative-solutions/mx-plan/email-generalities).
The required secret is the mailbox password, not your OVH customer-account
password, API token or Proton password. The script authenticates like a mail
client; an OVH API application is not part of this setup.

If your service appears under **Email Pro**, obtain its numbered server
(`proN.mail.ovh.net`) from that service's General information and use its
[Email Pro configuration guide](https://docs.ovhcloud.com/en/guides/web-cloud/email-and-collaborative-solutions/email-pro/thunderbird-macos-configuration).
For a standalone Zimbra/Exchange offer or a non-European service, use the
settings documented for that exact product before proceeding. This checker
supports implicit TLS, not STARTTLS-only endpoints.

If the address is already configured on your phone, keep that configuration
and enable its new-mail notifications. Otherwise add the mailbox to your mail
app using OVH's [device setup guides](https://docs.ovhcloud.com/en/guides/web-cloud/email-and-collaborative-solutions/mx-plan/email-creation#view-an-email-account-from-a-device).

### If you also use Proton

Domain registration at OVH does not establish where the mailbox is hosted.
Check the inbox you actually use. `dig +short MX YOUR_DOMAIN` shows advertised
incoming servers, but does not prove that a mailbox exists there. Records for
both providers need review before relying on alert delivery. Do not change MX
records merely to enable the VPS sender: that would affect all incoming mail
for the domain. An OVH SMTP setup requires a working OVH mailbox; a Proton
mailbox needs its own provider-specific setup.

If you are unsure: open OVH webmail and Proton Mail separately, check whether
this exact address has an inbox in each, and identify which account your phone
uses. Start with a successful OVH webmail login for the OVH procedure below.
If only Proton works, pause this procedure rather than supplying your Proton
password to OVH. Mail sent to the same address through OVH can be delivered
within OVH, so also confirm receipt in the particular inbox you monitor.

## 2. Store the mailbox password privately on the VPS

The health checker must already be deployed from the current `homelab-infra`
checkout. The commands below use its established location:

```sh
cd /opt/homelab-infra
./scripts/install-health --dry-run
sudo ./scripts/install-health --apply

# Create the directory only if absent; preserve existing application access.
sudo test -d /etc/homelab/secrets || sudo install -d -m 0700 /etc/homelab/secrets
# Create an empty credential only if absent; never truncate an existing one.
sudo sh -c 'test -e /etc/homelab/secrets/ovh-smtp-password || install -o root -g root -m 0600 /dev/null /etc/homelab/secrets/ovh-smtp-password'
sudoedit /etc/homelab/secrets/ovh-smtp-password
```

In the editor, enter **only the mailbox password on one line**, without quotes
or `password=`. Save and exit. Do not paste the password into chat or a shell
command. If the password is unknown, reset it through the mailbox's menu in
OVH, then update any phone/mail clients that use it before continuing.

## 3. Connect the credential and configure the address

```sh
cd /opt/homelab-infra
sudo install -d -m 0755 /etc/systemd/system/homelab-health.service.d
sudo install -o root -g root -m 0644 \
  systemd/homelab-health.service.d/50-ovh-credentials.conf.example \
  /etc/systemd/system/homelab-health.service.d/50-ovh-credentials.conf
sudo systemd-analyze verify /etc/systemd/system/homelab-health.service
sudo systemctl daemon-reload

# Preserve any existing host-local settings on a repeated setup.
sudo test -e /etc/homelab/alerts.toml || sudo install -o root -g root -m 0644 \
  templates/alerts.toml.example /etc/homelab/alerts.toml
sudoedit /etc/homelab/alerts.toml
```

Set `host` and `port` to the verified values from step 1. Set `username`,
`sender` and `recipient` to your complete mailbox address. For this VPS, use
the existing address from the host's example file. The file contains no password.
The existing five-minute timer will start attempting email delivery once this
configuration exists.

## 4. Send a test and confirm receipt

```sh
sudo env CREDENTIALS_DIRECTORY=/etc/homelab/secrets \
  /usr/local/sbin/homelab-check --test-email
```

A zero exit status means SMTP accepted the message; success is otherwise quiet.
Check the inbox and spam folder on your phone for **VPS alert delivery test**.
Do not consider notifications working until you receive it. Then verify the
normal systemd execution path:

```sh
sudo systemctl start homelab-health.service
systemctl show homelab-health.service -p Result -p ExecMainStatus
systemctl is-active homelab-health.timer
journalctl -u homelab-health.service --since '10 minutes ago' --no-pager
```

Expect `Result=success`, `ExecMainStatus=0` and an active timer when the health
checks also pass. Warnings alone do not fail the unit. A warning summary may
arrive on the first eligible check. Failure alerts require two consecutive
checks, recovery sends a message, and persistent failures get daily reminders.

## Troubleshooting and disabling

- **Mail is not configured:** `/etc/homelab/alerts.toml` is missing.
- **Configuration error:** check TOML keys and that the private credential file
  is nonempty. For timer runs, check that the credential drop-in is installed
  and `daemon-reload` completed. Do not print the password while diagnosing.
- **SMTP test failed:** first verify webmail login with the same mailbox, then
  verify the exact product/region hostname and port. The log intentionally
  avoids printing SMTP exception details that might contain private data.
- **SMTP accepted but nothing arrives:** check spam, mailbox rules and the
  intended provider's inbox, especially if MX records mention multiple providers.
- **Repeated failures:** delivery retries back off from five minutes to one hour.

To disable email while retaining health checks:

```sh
sudo mv /etc/homelab/alerts.toml /etc/homelab/alerts.toml.disabled
sudo rm /etc/systemd/system/homelab-health.service.d/50-ovh-credentials.conf
sudo systemctl daemon-reload
```

The private credential remains for deliberate reuse. A completely offline VPS
cannot send its own alerts; these notifications do not provide external uptime
monitoring.
