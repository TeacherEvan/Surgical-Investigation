"""
Tests for the surgical-investigation skill.

Validates that the skill file and template meet the authoring standards
and contain all required sections, frontmatter fields, and structural elements.

Run:  python -m pytest tests/ -v
       or:  python tests/skills/test_surgical_investigation_skill.py -v
"""

import pathlib
import re
import sys
import unittest
from unittest.mock import patch
from io import StringIO

SKILL_PATH = pathlib.Path(__file__).resolve().parent.parent.parent / "SKILL.md"
TEMPLATE_PATH = pathlib.Path(__file__).resolve().parent.parent.parent / "templates" / "report.html"


class TestFrontmatter(unittest.TestCase):
    """Validate SKILL.md frontmatter meets authoring standards."""

    @classmethod
    def setUpClass(cls):
        content = SKILL_PATH.read_text(encoding="utf-8")
        assert content.startswith("---"), "SKILL.md must start with ---"
        m = re.search(r"\n---\s*\n", content[3:])
        assert m, "Frontmatter must close with ---"
        import yaml
        cls.content = content
        cls.fm = yaml.safe_load(content[3 : m.start() + 3])
        cls.body = content[m.start() + 3 :]

    def test_starts_with_dashdash(self):
        self.assertTrue(self.content.startswith("---"), "Must start at byte 0 with ---")

    def test_name_present(self):
        self.assertIn("name", self.fm, "Missing 'name' field")

    def test_name_format(self):
        name = self.fm["name"]
        self.assertIsInstance(name, str)
        self.assertTrue(re.match(r"^[a-z0-9-]+$", name), f"name must be lowercase-hyphenated: {name!r}")
        self.assertLessEqual(len(name), 64, f"name too long: {len(name)} > 64")

    def test_name_is_surgical_investigation(self):
        self.assertEqual(self.fm["name"], "surgical-investigation")

    def test_description_present(self):
        self.assertIn("description", self.fm, "Missing 'description' field")

    def test_description_length(self):
        desc = self.fm["description"]
        self.assertLessEqual(len(desc), 60, f"description too long: {len(desc)} > 60 chars")

    def test_description_starts_with_use_when(self):
        desc = self.fm["description"]
        self.assertTrue(desc.startswith("Use when"), "description must start with 'Use when...'")

    def test_description_ends_with_period(self):
        self.assertTrue(self.fm["description"].endswith("."), "description must end with a period")

    def test_description_no_marketing_words(self):
        desc = self.fm["description"].lower()
        marketing = ["powerful", "comprehensive", "seamless", "advanced"]
        for word in marketing:
            self.assertNotIn(word, desc, f"description contains marketing word: {word}")

    def test_version_present(self):
        self.assertIn("version", self.fm, "Missing 'version' field")

    def test_version_semver(self):
        ver = self.fm["version"]
        self.assertIsInstance(ver, str)
        self.assertTrue(re.match(r"^\d+\.\d+\.\d+$", ver), f"version not semver: {ver!r}")

    def test_author_present(self):
        self.assertIn("author", self.fm, "Missing 'author' field")

    def test_author_credits_human(self):
        author = self.fm["author"]
        self.assertIn("Fenrie", author, "author must credit Fenrie (the human)")

    def test_license_present(self):
        self.assertIn("license", self.fm, "Missing 'license' field")
        self.assertEqual(self.fm["license"], "MIT", "license should be MIT")

    def test_platforms_present(self):
        self.assertIn("platforms", self.fm, "Missing 'platforms' field")
        self.assertIsInstance(self.fm["platforms"], list)
        self.assertTrue(len(self.fm["platforms"]) > 0, "platforms must not be empty")

    def test_metadata_hermes_tags(self):
        meta = self.fm.get("metadata", {})
        hermes = meta.get("hermes", {})
        self.assertIn("tags", hermes, "metadata.hermes.tags is required")
        self.assertIsInstance(hermes["tags"], list)
        self.assertTrue(len(hermes["tags"]) > 0, "tags must not be empty")
        # Check for investigation-related tag (either exact or as keyword)
        tags_lower = [t.lower() for t in hermes["tags"]]
        self.assertTrue(any(t in tags_lower for t in ["surgical-investigation", "investigation"]),
                        f"tags must include investigation-related tag, got: {hermes['tags']}")

    def test_skill_size(self):
        size = len(self.content)
        self.assertLessEqual(size, 100_000, f"skill too large: {size} > 100000 chars")


class TestBodyStructure(unittest.TestCase):
    """Validate SKILL.md body contains all required sections."""

    @classmethod
    def setUpClass(cls):
        cls.content = SKILL_PATH.read_text(encoding="utf-8")
        import yaml
        m = re.search(r"\n---\s*\n", cls.content[3:])
        cls.body = cls.content[m.start() + 3 :]

    def test_mode_selection_section(self):
        self.assertIn("Mode Selection", self.body, "Missing Mode Selection section")

    def test_scope_definition_section(self):
        self.assertIn("Scope Definition", self.body, "Missing Scope Definition section")

    def test_mission_verification_section(self):
        self.assertIn("Mission Verification", self.body, "Missing Mission Verification section")

    def test_dependency_audit_section(self):
        self.assertIn("Dependency Audit", self.body, "Missing Dependency Audit section")

    def test_best_practices_section(self):
        self.assertIn("Best Practices", self.body, "Missing Engineering Best Practices section")

    def test_optimality_section(self):
        self.assertIn("Optimality", self.body, "Missing Implementation Optimality section")

    def test_agent_files_audit_section(self):
        self.assertIn("Agent Files", self.body, "Missing Agent Files and Documentation Audit section")

    def test_external_sources_section(self):
        self.assertIn("External Source", self.body, "Missing External Source Investigation section")

    def test_mermaid_content(self):
        self.assertIn("Mermaid", self.body, "Missing Mermaid diagram guidance")

    def test_investigator_mode_section(self):
        self.assertIn("Investigator Mode", self.body, "Missing Investigator Mode section")

    def test_project_manager_mode_section(self):
        self.assertIn("Project-Manager Mode", self.body, "Missing Project-Manager Mode section")

    def test_yolo_mode_mentioned(self):
        self.assertTrue("YOLO" in self.body or "YOLO mode" in self.body, "Must mention YOLO mode")

    def test_recording_findings_section(self):
        self.assertIn("Recording Findings", self.body, "Missing Recording Findings section")

    def test_subagent_guidance(self):
        has_subagent = ("Use subagents" in self.body or
                        "dispatch subagents" in self.body or
                        "parallel subagents" in self.body)
        self.assertTrue(has_subagent, "Missing subagent usage guidance")

    def test_edge_cases_section(self):
        self.assertIn("Edge Cases", self.body, "Missing Edge Cases section")

    def test_completion_phrase(self):
        self.assertIn("This was the best I can do!", self.body,
                      "Must include the exact completion phrase for Project-Manager mode")

    def test_recommendation_guidance(self):
        # Skill must guide the agent to recommend features the PROJECT should add
        has_feature_recs = ("features the project should add" in self.body or
                            "Request Features" in self.body or
                            "interactive features" in self.body.lower() or
                            "feature recommendations" in self.body.lower())
        self.assertTrue(has_feature_recs, "Must include feature recommendation guidance")

    def test_no_machine_local_paths(self):
        local = re.findall(r"/home/leandi-duplessis/", self.body)
        self.assertEqual(len(local), 0, f"Body contains machine-local paths: {local}")

    def test_stand_first_instruction(self):
        # Skill must instruct agent to prompt/mode-select before acting
        has_stand_first = ("Prompt First" in self.body or
                           "stand first" in self.body.lower() or
                           ("mode selection" in self.body.lower() and "first" in self.body.lower()))
        self.assertTrue(has_stand_first,
                        "Must instruct agent to prompt before acting (mode selection first)")

    def test_clarification_triggers(self):
        # Skill must include clarification triggers for unclear scope
        has_triggers = ("Stop and ask" in self.body or
                        "STOP and ask" in self.body or
                        "ask if" in self.body.lower())
        self.assertTrue(has_triggers,
                        "Must include clarification triggers for unclear scope")


class TestQuickReference(unittest.TestCase):
    """Validate Quick Reference table is present and well-formed."""

    @classmethod
    def setUpClass(cls):
        content = SKILL_PATH.read_text(encoding="utf-8")
        m = re.search(r"\n---\s*\n", content[3:])
        cls.content = content
        cls.body = content[m.start() + 3 :]

    def test_quick_reference_table_present(self):
        self.assertIn("| Step | Action |", self.body, "Missing Quick Reference table header")

    def test_quick_reference_has_steps(self):
        # Should reference at least the key steps
        self.assertIn("Mode Selection", self.body)
        self.assertIn("Scope Definition", self.body)


class TestTemplateFile(unittest.TestCase):
    """Validate the HTML report template."""

    @classmethod
    def setUpClass(cls):
        if not TEMPLATE_PATH.exists():
            raise unittest.SkipTest(f"Template not found at {TEMPLATE_PATH}")
        cls.content = TEMPLATE_PATH.read_text(encoding="utf-8")

    def test_template_exists(self):
        self.assertTrue(TEMPLATE_PATH.exists(), "report.html template must exist")

    def test_template_is_html(self):
        self.assertIn("<!DOCTYPE html>", self.content, "Must be valid HTML5")

    def test_template_has_mermaid_script(self):
        self.assertIn("mermaid", self.content.lower(),
                      "Template must include Mermaid JS integration")

    def test_template_has_placeholder_project_name(self):
        self.assertIn("[PROJECT NAME]", self.content,
                      "Template must use [PROJECT NAME] placeholder")

    def test_template_has_placeholder_date(self):
        self.assertIn("[DATE]", self.content,
                      "Template must use [DATE] placeholder")

    def test_template_has_implement_button(self):
        self.assertIn("IMPLEMENT FINDINGS/RECOMMENDATIONS", self.content,
                      "Template must have the IMPLEMENT button")

    def test_template_has_followup_button(self):
        self.assertTrue("follow-up" in self.content.lower() or "followup" in self.content.lower(),
                        "Template must have a follow-up request mechanism")

    def test_template_dark_theme(self):
        # Check for dark theme CSS variables
        css = self.content.lower()
        has_dark = any(kw in css for kw in ["#0d1117", "dark", "var(--bg)"])
        self.assertTrue(has_dark, "Template should have dark theme styling")

    def test_template_has_modal(self):
        self.assertIn("modal", self.content.lower(),
                      "Template should include a modal for follow-up requests")

    def test_template_size_under_limit(self):
        size = len(self.content)
        self.assertLessEqual(size, 50_000,
                             f"Template too large: {size} bytes (limit 50000)")


class TestRelatedSkills(unittest.TestCase):
    """Validate related_skills entries resolve to real skills."""

    @classmethod
    def setUpClass(cls):
        cls.content = SKILL_PATH.read_text(encoding="utf-8")
        import yaml
        m = re.search(r"\n---\s*\n", cls.content[3:])
        cls.fm = yaml.safe_load(cls.content[3 : m.start() + 3])

    def test_related_skills_includes_executing_plans(self):
        related = self.fm.get("metadata", {}).get("hermes", {}).get("related_skills", [])
        self.assertIn("superpowers:executing-plans", related,
                      "Must reference superpowers:executing-plans")

    def test_related_skills_includes_verification(self):
        related = self.fm.get("metadata", {}).get("hermes", {}).get("related_skills", [])
        self.assertIn("superpowers:verification-before-completion", related,
                      "Must reference superpowers:verification-before-completion")

    def test_related_skills_includes_debugging(self):
        related = self.fm.get("metadata", {}).get("hermes", {}).get("related_skills", [])
        self.assertIn("superpowers:systematic-debugging", related,
                      "Must reference superpowers:systematic-debugging")


class TestIntegration(unittest.TestCase):
    """Integration tests — verify the skill as a whole is coherent."""

    @classmethod
    def setUpClass(cls):
        cls.content = SKILL_PATH.read_text(encoding="utf-8")
        import yaml
        m = re.search(r"\n---\s*\n", cls.content[3:])
        cls.fm = yaml.safe_load(cls.content[3 : m.start() + 3])
        cls.body = cls.content[m.start() + 3 :]

    def test_investigator_builds_report(self):
        """Documented behavior: Investigator mode generates HTML report."""
        self.assertTrue(
            ("HTML report" in self.body and "Investigator" in self.body) or
            ("report" in self.body.lower() and "Investigator" in self.body),
            "Investigator mode must document HTML report generation"
        )

    def test_project_manager_does_not_generate_report(self):
        """Project-Manager mode must explicitly NOT generate a report."""
        pm_section = self.body.split("Project-Manager Mode")
        self.assertTrue(len(pm_section) > 1, "Must have a Project-Manager Mode section")
        pm_body = pm_section[1].split("---")[0] if "---" in pm_section[1] else pm_section[1]
        # Should mention skipping the report
        self.assertTrue(
            "NO report" in pm_body or "skip" in pm_body.lower() or "not generate" in pm_body.lower(),
            "Project-Manager mode must state it skips the HTML report"
        )

    def test_both_modes_share_investigation(self):
        """Both modes must share the same 7-step investigation flow."""
        steps_mentioned = sum(1 for s in [
            "Scope Definition", "Mission Verification", "Dependency Audit",
            "Best Practices", "Optimality", "Agent Files", "External Source"
        ] if s in self.body)
        self.assertGreaterEqual(steps_mentioned, 5,
                                f"Both modes share investigation: only {steps_mentioned}/7 steps found")


class TestNewFeatures(unittest.TestCase):
    """Tests for v1.1.0 features: strategy system, budgets, cache, refinement, formats, composition."""

    @classmethod
    def setUpClass(cls):
        cls.content = SKILL_PATH.read_text(encoding="utf-8")
        import yaml
        m = re.search(r"\n---\s*\n", cls.content[3:])
        cls.body = cls.content[m.start() + 3:]

    def test_version_is_1_1_0_or_later(self):
        import yaml
        content = SKILL_PATH.read_text(encoding="utf-8")
        m = re.search(r"\n---\s*\n", content[3:])
        self.assertIsNotNone(m, "Frontmatter delimiter missing")
        fm = yaml.safe_load(content[3:m.start() + 3])
        ver = fm.get("version", "")
        # Should be at least 1.1.0 (or higher minor)
        match = re.match(r"^(\d+)\.(\d+)\.\d+$", ver)
        self.assertIsNotNone(match, f"version not semver: {ver}")
        major, minor = int(match.group(1)), int(match.group(2))
        self.assertGreaterEqual(minor, 1, f"Expected version >= 1.1.0, got {ver}")

    def test_search_strategy_selection_step(self):
        # Step 0.5: Search Strategy Selection must exist
        self.assertIn("Step 0.5", self.body, "Missing Step 0.5 (Search Strategy Selection)")
        self.assertIn("Search Strategy", self.body, "Missing Search Strategy section")

    def test_eight_strategies_documented(self):
        # All 8 strategies should be mentioned
        strategies = [
            "codebase-first", "targeted-docs", "error-driven",
            "rule-id-driven", "cve-driven", "pattern-driven",
            "community-pulse", "full-sweep"
        ]
        for strategy in strategies:
            self.assertIn(strategy, self.body,
                          f"Strategy '{strategy}' not documented")

    def test_strategy_budget_documented(self):
        # Budget references should exist
        has_budget = ("budget" in self.body.lower() or
                      "Budget" in self.body or
                      "subagent" in self.body.lower())
        self.assertTrue(has_budget, "Search budget/reference missing")

    def test_search_budgets_table(self):
        # Budget table with subagents/sources/time should exist
        body_lower = self.body.lower()
        has_subagent_budget = "subagent" in body_lower or "budget" in body_lower
        self.assertTrue(has_subagent_budget,
                        "Search budget table/reference missing")

    def test_incremental_cache_reference(self):
        # Step 0.7: Cache system
        self.assertIn("Step 0.7", self.body, "Missing Step 0.7 (Incremental Cache)")
        self.assertIn("cache", self.body.lower(), "Cache system not mentioned")

    def test_quick_search_mode(self):
        # Quick Search Mode (lightweight path)
        self.assertIn("Quick Search", self.body,
                      "Quick Search Mode not documented")

    def test_interactive_refinement(self):
        # Interactive refinement options
        refinement_mentioned = ("Interactive Refinement" in self.body or
                                "refinement" in self.body.lower())
        self.assertTrue(refinement_mentioned,
                        "Interactive Refinement section not documented")

    def test_output_formats_step_7_5(self):
        # Step 7.5: Multiple output formats
        step_75_found = ("Step 7.5" in self.body or "Output Formats" in self.body)
        self.assertTrue(step_75_found,
                      "Step 7.5 / Output Formats section missing")
        # Check for multiple format names
        formats = ["JSON", "Markdown", "SARIF"]
        found_formats = [f for f in formats if f in self.body]
        self.assertGreaterEqual(len(found_formats), 2,
                                f"Expected at least 2 of {formats} in body, found: {found_formats}")

    def test_sarif_mentioned(self):
        # SARIF format specifically
        self.assertIn("SARIF", self.body, "SARIF output format not mentioned")

    def test_skill_composition_reference(self):
        # Composition principle: surgical-investigation as orchestrator
        has_composition = ("orchestrator" in self.body.lower() or
                           "orchestrat" in self.body.lower() or
                           "composition" in self.body.lower() or
                           "delegate" in self.body.lower())
        self.assertTrue(has_composition,
                        "Skill composition / orchestrator principle not mentioned")

    def test_agent_surgery_family_skills(self):
        # AgentSurgery family skills referenced
        family_skills = [
            "surgical-orchestration", "surgical-implementation",
            "surgical-hermesdothealth"
        ]
        found = [s for s in family_skills if s in self.body]
        self.assertGreaterEqual(len(found), 1,
                                f"AgentSurgery family skills not referenced (expected at least 1 of {family_skills})")

    def test_source_credibility_tiers(self):
        # Source credibility scoring system
        has_credibility = ("credibility" in self.body.lower() or
                           "tier" in self.body.lower() or
                           "weight" in self.body.lower())
        self.assertTrue(has_credibility,
                        "Source credibility / tier scoring not mentioned")


if __name__ == "__main__":
    # Allow running directly: python test_surgical_investigation_skill.py
    unittest.main(verbosity=2)
