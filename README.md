<p align="center"><img src="resources/SuricataPi_Logo_black.png" alt="SuricataPi" style="width:20%;"/>

[![GitHub license](https://img.shields.io/github/license/beep-projects/SuricataPi)](https://github.com/beep-projects/SuricataPi/blob/main/LICENSE) [![shellcheck](https://github.com/beep-projects/SuricataPi/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/beep-projects/SuricataPi/actions/workflows/shellcheck.yml) [![GitHub issues](https://img.shields.io/github/issues/beep-projects/SuricataPi)](https://github.com/beep-projects/SuricataPi/issues) [![GitHub forks](https://img.shields.io/github/forks/beep-projects/SuricataPi)](https://github.com/beep-projects/SuricataPi/network) [![GitHub stars](https://img.shields.io/github/stars/beep-projects/SuricataPi)](https://github.com/beep-projects/SuricataPi/stargazers) ![GitHub repo size](https://img.shields.io/github/repo-size/beep-projects/SuricataPi)![visitors](https://visitor-badge.glitch.me/badge?page_id=beep-projects.SuricataPi)

</p>
This projects hosts scripts to setup a Raspberry Pi as intrusion detection system (IDS) for home networks based on [Suricata](https://suricata.io/) and [ELK stack](https://www.elastic.co/what-is/elk-stack). The configured system collects Suricata [eve.json](https://suricata.readthedocs.io/en/latest/output/eve/eve-json-output.html) logs and feeds them into the ELK stack for analysis. This data includes alerts, flows, http, dns, statistics and other log types, which you can easily access to create your own dashboards. This project was inspired by (outdated) projects like [SELKS](https://github.com/StamusNetworks/SELKS) and [sýnesis lite](https://github.com/robcowart/synesis_lite_suricata).



<img src="resources/SuricataPi_overview.png" width="500">





Required Hardware

Raspberry Pi 4 Model B Rev 1.5, 2GB RAM

