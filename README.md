# Kyreth-VPN Public Configs

A centralized, automated repository for compiling, managing, and distributing proxy rule-sets (Rule Providers) for various proxy cores. 

Currently optimized for **Mihomo**, with a modular architecture designed to easily extend support to **Sing-box**, **Stash**, and **Xray** in the future.

---

## 🚀 Features

- **Automated Compilation**: GitHub Actions automatically compile human-readable `.list` files into highly optimized `.mrs` (Mihomo Rule Set) binary formats.
- **Clean Release Branch**: All compiled artifacts are pushed to a dedicated `release` branch, keeping the `main` branch clean for source code and configuration.
- **Direct Raw URL Access**: Rules are instantly accessible via standard raw GitHub URLs, perfect for direct integration into your proxy client configurations.
- **Modular Architecture**: A top-level orchestrator (`compile-rules.sh`) delegates compilation to core-specific scripts (e.g., `mihomo/compile.sh`), making it trivial to add new proxy cores.
- **Automated Releases**: Successful compilations trigger the creation of `.zip` archives for each core, which are then published as GitHub Releases.

---

## 📥 How to Use the Rules

You can directly reference the compiled rule-sets in your proxy client configuration using raw GitHub URLs. 

### URL Format
```text
https://raw.githubusercontent.com/Kyreth-VPN/public-configs/release/{core}/{category}/{rule-name}.{extension}
```

### Example: Mihomo Rule Provider
To use the `category-vladlink-blocked` rule-set in your Mihomo `config.yaml`, add the following to your `rule-providers` section:

```yaml
rule-providers:
  category-vladlink-blocked:
    type: http
    behavior: domain
    url: "https://raw.githubusercontent.com/Kyreth-VPN/public-configs/release/mihomo/geosite/category-vladlink-blocked.mrs"
    path: ./rule-sets/geosite/category-vladlink-blocked.mrs
    interval: 86400
    format: mrs
```

Then, reference it in your rules section:

```yaml
rules:
  - RULE-SET,category-vladlink-blocked,REJECT
```

> [!Note]
> Both .mrs and .list formats are available in the release branch.

## ⚙️ How It Works (CI/CD)
The repository relies on a robust, two-stage GitHub Actions pipeline:
  1. `publish-rules.yml`:
    - Triggered manually (workflow_dispatch) or on pushes to main.
    - Installs dependencies (yq, mihomo binary).
    - Runs compile-rules.sh, which iterates through supported cores and compiles .list files into .mrs format.
    - Checks out the release branch, cleans it, and pushes the newly compiled artifacts.
  2. `make-release.yml`:
    - Triggered automatically upon the successful completion of publish-rules.yml.
    - Checks out the release branch.
    - Dynamically archives each core's directory (e.g., mihomo.zip, sing-box.zip).
    - Creates a new GitHub Release tagged as latest with a random hex identifier, attaching the .zip archives.

## 🛠️ Adding a New Rule
  
  1. Navigate to the appropriate directory (e.g., `mihomo/rule-sets/geosite/`).
  2. Create a new folder named after your rule (e.g., `my-custom-rule`).
  3. Add a `meta.yaml` file defining the behavior:
     ``` yaml
     behavior: domain # or 'ipcidr', or 'classical'
     description: >
       My first rule-set.
     ```
 4. Add a `rule.list` file containing your rules (one per line, # for comments).
 5. Make Pull Request.

## 📜 License
This project is licensed under the terms specified in the [LICENSE](#LICENSE.md) file.

> [!TIP]
> Always use the release branch URLs for your configurations,
> as the main branch only contains the source .list files and not the compiled .mrs binaries.
