import os
import unittest

os.environ.setdefault("MANGO_KEY", "test-key-not-used")

from mangopi_cli import OpenAIProvider  # noqa: E402


class TestTaggedContentCleanup(unittest.TestCase):
    def test_complete_think_and_confirmation_tags_are_cleaned(self):
        provider = OpenAIProvider("http://x/v1/chat/completions", "k", "qwen3-32b")
        parsed = provider.parse_response({
            "choices": [{
                "finish_reason": "stop",
                "message": {
                    "role": "assistant",
                    "content": (
                        "<think>\n"
                        "这里是模型思考内容\n"
                        "</think>\n\n"
                        "<confirmation>\n"
                        "需要我尝试使用替代方案吗？(y/n)\n"
                        "</confirmation>"
                    ),
                },
            }],
            "usage": {"prompt_tokens": 1, "completion_tokens": 2},
        })

        self.assertEqual(parsed["content"], "需要我尝试使用替代方案吗？(y/n)")
        self.assertIn("模型思考内容", parsed["reasoning_content"])
        self.assertEqual(parsed["confirmation_content"], "需要我尝试使用替代方案吗？(y/n)")
        self.assertNotIn("<think>", parsed["raw_message"]["content"])
        self.assertNotIn("</think>", parsed["raw_message"]["content"])
        self.assertNotIn("<confirmation>", parsed["raw_message"]["content"])

    def test_normal_think_tag_is_extracted(self):
        cleaned = OpenAIProvider.clean_tagged_content(
            "<think>hidden reasoning</think>\nVisible answer",
            reasoning="",
        )
        self.assertEqual(cleaned["content"], "Visible answer")
        self.assertEqual(cleaned["reasoning_content"], "hidden reasoning")


if __name__ == "__main__":
    unittest.main()
