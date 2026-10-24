# Due-Diligence Benchmarks for Non-Codebase Investigations

When investigating a company, person, or service provider (OSINT/desk research), two benchmark techniques consistently produce high-value findings beyond the initial source triangulation.

## 1. Regulatory Requirements Benchmark

Compare what the law requires against what the subject actually publishes. This surfaces compliance gaps that are invisible in a simple "is it registered?" check.

**Procedure:**
1. Identify the applicable regulatory framework for the subject's industry (e.g., PSIRA Act for SA security, CIPC for SA companies, Firearms Control Act for armed services, POPIA for privacy).
2. For each requirement, document: what the law requires (with section reference), what the subject publishes, and the source tier.
3. Produce a comparison table: Requirement | Law requires | Subject publishes | Source.
4. Flag any requirement where the subject publishes nothing or only a generic label (e.g., "Privacy Policy" without POPIA s.18 content).

**Common regulatory frameworks by domain:**
- SA private security: PSIRA Act 56 of 2001 (registration, grades, categories, renewal), Companies Act 71 of 2008 (CIPC number on communications), Firearms Control Act 60 of 2000 (competency + per-firearm licence + institutional licence), POPIA Act 4 of 2013 (s.17 PAIA manual, s.18 notification, s.19 safeguards).
- General SA company: CIPC registration, annual returns, director filings, tax compliance (SARS).
- General: industry body membership, SETA registration, professional licensing.

**Pitfall:** Do not treat "not published on the website" as "not compliant." The absence of public display is a transparency gap, not necessarily a compliance failure. The subject may hold valid certificates they simply don't publish. Frame findings as "unverified from public sources" not "non-compliant."

## 4. SA Security Industry — Verification Portals and Resources

For South African private security investigations, these portals are the Tier-1 verification sources:

| Portal | URL | What it verifies | How to use |
|--------|-----|------------------|------------|
| PSIRA digital services | `https://digitalservices.psira.co.za/verify-user/4` | PSIRA registration number, grade, category, renewal status | Enter PSIRA No. in the "Verify User" form. Angular SPA — requires manual interaction or browser automation. |
| PSIRA withdrawn list | `https://www.psira.co.za/index.php/publicity/consumer-awareness` | PSIRA registration status (active/withdrawn) | Download the withdrawn companies list PDF (dated lists, e.g., 31-01-2025). Search by company name or SIRA number. |
| CIPC company search | `https://www.cipc.co.za/` (search via e-services portal) | CIPC registration number, director names, registered address, company status | Requires free login. Search by company name or registration number. |
| CIPC via directories | `companies-southafrica.com`, `bizportal.gov.za` | Indirect CIPC data (often incomplete) | Useful for initial screening; not authoritative. Always verify via official CIPC portal. |
| SAFLII | `https://www.saflii.org/` | Court records (Labour Court, High Court, etc.) | Search by party name. Default judgments are published; contested matters may require direct court inquiry. |
| HelloPeter | `https://www.hellopeter.com/` | Consumer complaints | Search by company name. Note: unclaimed profiles may have stale or incomplete complaint data. |

**Pitfall — PSIRA portal is an Angular SPA.** The PSIRA digital services portal (`digitalservices.psira.co.za`) is a single-page application that does not respond to `curl` or simple HTTP requests. `web_extract` and `web_search` will not return useful data. Use browser automation (new_tab → fill PSIRA No. → submit) or document the manual verification URL and instruct the user to check it themselves. Do not report "PSIRA verification failed" when the issue is that the portal requires interactive browser use.

**Pitfall — PSIRA withdrawn list name collisions.** The PSIRA withdrawn list publishes entries as "SIRA No. | COMPANY NAME | TRADE NAME | STATUS". A company may appear under a different legal entity name with your target as the trade name (e.g., "APPLIED FLUORINE ENGINEERING (PTY) LTD" with trade name "PLATINUM RISK SOLUTIONS"). This is a name collision, not proof that the target company is withdrawn — it may indicate brand reuse, entity restructuring, or an alias. Always verify via the PSIRA digital services portal using the target's PSIRA registration number before concluding a registration is withdrawn.

**Pitfall — CIPC data behind portal.** CIPC registration details (number, directors, address) are behind a login portal. Public directories (`companies-southafrica.com`, `bizportal.gov.za`) often have incomplete or stale data. A company's CIPC number may not appear on its website, marketing materials, or directory listings. Treat "CIPC number not found" as "not publicly disclosed" — not "not registered." The absence of a CIPC number in public sources is common for SA SMEs and is not a compliance failure.

**Pitfall — Labour Court default judgments are not merits rulings.** A default judgment (e.g., J 3914/18) means the defendant did not appear; it is an uncontested record, not an adjudicated finding of liability. It establishes that a claim was filed and no defence was entered. Do not describe it as "found liable" or "convicted." Frame as: "default judgment entered; defendant did not appear; merits not adjudicated."

## 2. Industry Transparency Benchmark

Compare the subject against 3-5 peer providers in the same industry and region to establish what is "normal" vs "outlier."

**Procedure:**
1. Select peers: same industry, same region, similar size. Include both large (established) and medium (comparable) providers.
2. For each peer, check the same transparency elements: CIPC number, regulatory registration number, physical address, director names, privacy/POPIA notice, client references, named testimonials.
3. Produce a comparison table: Element | Provider A | Provider B | ... | Subject.
4. State a conclusion: which gaps are industry-norm (not worth flagging as red flags) and which are genuine outliers (worth flagging).

**Key insight from SA security industry (Oct 2026):**
- Physical address + regulatory registration are the most consistently disclosed (all publish address; 2 of 5 publish registration numbers).
- CIPC numbers, director names, POPIA/PAIA notices are rarely published (only 1 of 5 discloses CIPC numbers via PAIA manual).
- Client references and named testimonials are universally absent — industry norm due to confidentiality of security arrangements.
- Conclusion: lack of transparency is largely typical; the outlier worth flagging is missing regulatory registration display and any compliance page, which even medium providers publish.

**Pitfall:** Do not flag industry-norm gaps as red flags. A provider that omits CIPC numbers is not unusual — most do. Flag only genuine outliers (e.g., no PSIRA display when peers publish theirs, no physical address when all peers publish one).

## 3. Validated Subagent Fan-Out for Desk Research

For OSINT/desk-research investigations, the validated 3-subagent fan-out is:

1. **Exhaustive public-record search** — search all public registries, directories, court records, review sites, social media, news, and industry bodies for the subject. Confirm both what exists AND what doesn't (absence is a finding).
2. **Regulatory requirements research** — identify all applicable laws/regulations and benchmark against what the subject publishes (see technique 1 above).
3. **Industry transparency benchmark** — compare against 3-5 peer providers (see technique 2 above).

Dispatch all three in parallel. Synthesize results into the report's findings, regulatory benchmark section, and industry benchmark section respectively.

**Pitfall:** Do not generate final reports before the subagent verification pass completes. The correct sequence is: (1) dispatch subagents, (2) read results and revise findings, (3) THEN generate all output formats. Reports generated before verification are stale on arrival.
