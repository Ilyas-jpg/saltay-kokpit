---
name: Verification surface — which job, which tool
description: Which browser or tool to use for measuring, for what the user sees, for showing things to the user, for deliverables, deploy checks and demos. One decision table for verification rules born from separate incidents; read alone, one rule made you break another.
type: reference
created: {{INSTALL_DATE}}
---

# Verification surface

> Verification rules are born from separate incidents and, read one by one, make you break each other:
> a "look in the user's browser" rule gets applied to a measurement job, an image opened with `Read` is
> assumed to have been shown to the user. Check this table first; add your own machine's traps as rows.

| Job | Tool | Why |
|---|---|---|
| Responsive / mobile measurement (overflow, bbox) | A headless browser (e.g. Playwright): set the viewport, then ask the page for `innerWidth`; `scrollWidth - innerWidth > 0` means overflow | Don't trust emulation: on a 200 %-scaled Windows screen some panels' "mobile" mode showed the page ~765 px when 390 was requested; a page declared "no mobile overflow" overflowed on the phone |
| QA a visual output with your own eyes | Headless screenshot → look at it with `Read`, every iteration | No blind delivery; add programmatic checks but don't let them replace looking |
| What the user sees live (cache, real viewport) | The user's own browser (browser extension; pick the one on this computer, K3) | Headless is a separate instance; cache and viewport differ |
| Did the deploy land | `curl` + grep the live HTML, HTTP 200, a bumped cache-buster `?v=` | Fast and exact; take a screenshot separately for composition |
| Showing / letting the user pick visuals | A small HTML gallery → open it in the user's default browser (Windows `Start-Process`, macOS `open`); light + dark backgrounds, labelled | An image you open with `Read` stays in your context only; the user never sees it |
| Deliverables (audio, video, images, PDF, documents) | A visible delivery folder, `<Project>/01 - <Content name>.<ext>`; an HTML document gets a PDF with the same name next to it | No searching for it; HTML doesn't open on phones or in messaging apps |
| PDF (produced from HTML) | No `box-shadow` or transparency, separate surfaces with opaque colours; before delivery count `/SMask` in the PDF → 0 | Desktop viewers render it fine, iOS PDF viewers paint the shadow as a black box |
| Demo / live tour ("walk me through") | Prepare (seed, login, page list), hand control to the user | An automated tour is slow and worthless; the preparation is the value |
| An in-app browser panel | DOM / text / overflow measurement only | While the panel is hidden, animations freeze, screenshots come back blank, lazy content never loads: a measurement artefact, not a site bug |
| Before telling someone "your link is broken" | Open it in a clean session, in phone view; measure the final URL and the page text | Never judge from what one browser showed |

**Short decision:** measuring → headless; what the user sees → their browser; showing them → gallery +
default browser + delivery folder; demo → prepare, don't drive; in-app panel → measurement only.

Related: [[feedback_5_canonical_rules]] (K3)
