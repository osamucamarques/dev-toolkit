# Coupling Analysis — Report Template

Use this structure for Phase 6 output.

## 6.1 Executive Summary

```
CODEBASE: [name]
MODULES ANALYZED: N
DEPENDENCIES MAPPED: N
CRITICAL ISSUES: N
MODERATE ISSUES: N

OVERALL HEALTH SCORE: [Healthy / Attention / Critical]
```

## 6.2 Dependency Map

```
[ModuleA] --[INTRUSIVE]-----------> [ModuleB]
[ModuleC] --[CONTRACT]------------> [ModuleD]
```

## 6.3 Identified Issues (by severity)

For each critical or moderate issue, report: modules involved, coupling type, dimensions (strength/distance/volatility), balance score, impact, and recommendation.

## 6.4 Positive Patterns Found

List modules with well-implemented contract coupling, minimal model leakage, etc.

## 6.5 Prioritized Recommendations

High priority (blocking evolution) → Medium priority (architectural health) → Low priority (incremental).
