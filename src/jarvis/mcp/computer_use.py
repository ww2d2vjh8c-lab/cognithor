"""Computer Use — GPT-5.4-style desktop automation via screenshots + coordinate clicking.

Takes screenshots of the desktop, sends them to a vision model for analysis,
and executes mouse/keyboard actions at specific coordinates. Enables Cognithor
to interact with any application through its visual interface.

Requires: pyautogui, mss (for fast screenshots)
"""

from __future__ import annotations

import asyncio
import base64
import io
import json
import logging
import time
from typing import Any

log = logging.getLogger(__name__)

# Lazy imports to avoid startup cost
_pyautogui = None
_mss = None


def _get_pyautogui():
    global _pyautogui
    if _pyautogui is None:
        import pyautogui

        pyautogui.FAILSAFE = True  # Move mouse to corner to abort
        pyautogui.PAUSE = 0.1  # Small pause between actions
        _pyautogui = pyautogui
    return _pyautogui


def _get_mss():
    global _mss
    if _mss is None:
        import mss

        _mss = mss
    return _mss


def _take_screenshot_b64() -> tuple[str, int, int]:
    """Take a desktop screenshot, return (base64_png, width, height)."""
    mss = _get_mss()
    with mss.mss() as sct:
        monitor = sct.monitors[0]  # All monitors combined
        img = sct.grab(monitor)
        # Convert to PNG bytes
        from PIL import Image

        pil_img = Image.frombytes("RGB", img.size, img.bgra, "raw", "BGRX")
        # Resize for vision model (max 1920px wide to save tokens)
        max_w = 1920
        if pil_img.width > max_w:
            ratio = max_w / pil_img.width
            pil_img = pil_img.resize((max_w, int(pil_img.height * ratio)), Image.LANCZOS)
        buf = io.BytesIO()
        pil_img.save(buf, format="PNG", optimize=True)
        b64 = base64.b64encode(buf.getvalue()).decode("ascii")
        return b64, pil_img.width, pil_img.height


class ComputerUseTools:
    """MCP tools for desktop computer use via vision + coordinates."""

    def __init__(self, vision_analyzer: Any = None) -> None:
        self._vision = vision_analyzer

    async def computer_screenshot(self) -> dict[str, Any]:
        """Take a screenshot of the desktop and describe what's visible."""
        try:
            b64, width, height = await asyncio.get_event_loop().run_in_executor(
                None, _take_screenshot_b64
            )
            description = ""
            if self._vision:
                try:
                    description = await self._vision.analyze_image_b64(
                        b64,
                        prompt=(
                            "Describe what you see on this desktop screenshot. "
                            "List all visible windows, buttons, text fields, and UI elements "
                            "with their approximate positions (top-left, center, bottom-right etc). "
                            "If there's a browser, describe the page content."
                        ),
                    )
                except Exception as exc:
                    description = f"Vision analysis failed: {exc}"

            return {
                "success": True,
                "width": width,
                "height": height,
                "description": description,
                "screenshot_b64": b64[:100] + "...",  # Truncated for response
            }
        except Exception as exc:
            return {"success": False, "error": str(exc)}

    async def computer_click(
        self,
        x: int,
        y: int,
        button: str = "left",
        clicks: int = 1,
    ) -> dict[str, Any]:
        """Click at specific coordinates on the desktop."""
        try:
            gui = _get_pyautogui()
            await asyncio.get_event_loop().run_in_executor(
                None, lambda: gui.click(x=x, y=y, button=button, clicks=clicks)
            )
            log.info("computer_click", x=x, y=y, button=button, clicks=clicks)
            return {
                "success": True,
                "action": "click",
                "x": x,
                "y": y,
                "button": button,
                "clicks": clicks,
            }
        except Exception as exc:
            return {"success": False, "error": str(exc)}

    async def computer_type(
        self,
        text: str,
        interval: float = 0.02,
    ) -> dict[str, Any]:
        """Type text using the keyboard."""
        try:
            gui = _get_pyautogui()
            await asyncio.get_event_loop().run_in_executor(
                None,
                lambda: gui.typewrite(text, interval=interval)
                if text.isascii()
                else gui.write(text),
            )
            log.info("computer_type", text_len=len(text))
            return {"success": True, "action": "type", "text_length": len(text)}
        except Exception as exc:
            return {"success": False, "error": str(exc)}

    async def computer_hotkey(self, *keys: str) -> dict[str, Any]:
        """Press a keyboard shortcut (e.g., ctrl+c, alt+tab)."""
        try:
            gui = _get_pyautogui()
            await asyncio.get_event_loop().run_in_executor(None, lambda: gui.hotkey(*keys))
            log.info("computer_hotkey", keys=keys)
            return {"success": True, "action": "hotkey", "keys": list(keys)}
        except Exception as exc:
            return {"success": False, "error": str(exc)}

    async def computer_scroll(
        self, x: int, y: int, direction: str = "down", amount: int = 3
    ) -> dict[str, Any]:
        """Scroll at specific coordinates."""
        try:
            gui = _get_pyautogui()
            clicks = -amount if direction == "down" else amount
            await asyncio.get_event_loop().run_in_executor(
                None, lambda: gui.scroll(clicks, x=x, y=y)
            )
            log.info("computer_scroll", x=x, y=y, direction=direction, amount=amount)
            return {
                "success": True,
                "action": "scroll",
                "x": x,
                "y": y,
                "direction": direction,
            }
        except Exception as exc:
            return {"success": False, "error": str(exc)}

    async def computer_move(self, x: int, y: int) -> dict[str, Any]:
        """Move the mouse to specific coordinates without clicking."""
        try:
            gui = _get_pyautogui()
            await asyncio.get_event_loop().run_in_executor(
                None, lambda: gui.moveTo(x=x, y=y, duration=0.3)
            )
            return {"success": True, "action": "move", "x": x, "y": y}
        except Exception as exc:
            return {"success": False, "error": str(exc)}

    async def computer_drag(
        self, start_x: int, start_y: int, end_x: int, end_y: int
    ) -> dict[str, Any]:
        """Drag from start coordinates to end coordinates."""
        try:
            gui = _get_pyautogui()
            await asyncio.get_event_loop().run_in_executor(
                None,
                lambda: (
                    gui.moveTo(start_x, start_y),
                    gui.drag(end_x - start_x, end_y - start_y, duration=0.5, button="left"),
                ),
            )
            log.info(
                "computer_drag",
                start_x=start_x,
                start_y=start_y,
                end_x=end_x,
                end_y=end_y,
            )
            return {
                "success": True,
                "action": "drag",
                "start": [start_x, start_y],
                "end": [end_x, end_y],
            }
        except Exception as exc:
            return {"success": False, "error": str(exc)}


def register_computer_use_tools(
    client: Any,
    vision_analyzer: Any = None,
) -> ComputerUseTools | None:
    """Register computer use MCP tools."""
    try:
        _get_pyautogui()  # Test if pyautogui works
    except Exception:
        log.debug("computer_use_skip", reason="pyautogui not available")
        return None

    tools = ComputerUseTools(vision_analyzer=vision_analyzer)

    client.register_tool(
        name="computer_screenshot",
        description=(
            "Take a screenshot of the desktop and describe visible UI elements. "
            "Use this to see what's on screen before clicking."
        ),
        handler=tools.computer_screenshot,
        input_schema={"type": "object", "properties": {}},
    )

    client.register_tool(
        name="computer_click",
        description=(
            "Click at specific pixel coordinates on the desktop. "
            "Use computer_screenshot first to identify element positions."
        ),
        handler=tools.computer_click,
        input_schema={
            "type": "object",
            "properties": {
                "x": {"type": "integer", "description": "X pixel coordinate"},
                "y": {"type": "integer", "description": "Y pixel coordinate"},
                "button": {
                    "type": "string",
                    "enum": ["left", "right", "middle"],
                    "description": "Mouse button (default: left)",
                },
                "clicks": {
                    "type": "integer",
                    "description": "Number of clicks (default: 1, use 2 for double-click)",
                },
            },
            "required": ["x", "y"],
        },
    )

    client.register_tool(
        name="computer_type",
        description="Type text using the keyboard. Click a text field first.",
        handler=tools.computer_type,
        input_schema={
            "type": "object",
            "properties": {
                "text": {"type": "string", "description": "Text to type"},
                "interval": {
                    "type": "number",
                    "description": "Delay between keystrokes in seconds (default: 0.02)",
                },
            },
            "required": ["text"],
        },
    )

    client.register_tool(
        name="computer_hotkey",
        description=(
            "Press a keyboard shortcut. Examples: ctrl+c, ctrl+v, alt+tab, enter, escape."
        ),
        handler=tools.computer_hotkey,
        input_schema={
            "type": "object",
            "properties": {
                "keys": {
                    "type": "string",
                    "description": "Keys separated by + (e.g., 'ctrl+c', 'alt+tab', 'enter')",
                },
            },
            "required": ["keys"],
        },
    )

    client.register_tool(
        name="computer_scroll",
        description="Scroll at specific coordinates on the desktop.",
        handler=tools.computer_scroll,
        input_schema={
            "type": "object",
            "properties": {
                "x": {"type": "integer", "description": "X coordinate"},
                "y": {"type": "integer", "description": "Y coordinate"},
                "direction": {
                    "type": "string",
                    "enum": ["up", "down"],
                    "description": "Scroll direction",
                },
                "amount": {
                    "type": "integer",
                    "description": "Scroll amount (default: 3)",
                },
            },
            "required": ["x", "y"],
        },
    )

    client.register_tool(
        name="computer_drag",
        description="Drag from one position to another (e.g., for drag-and-drop).",
        handler=tools.computer_drag,
        input_schema={
            "type": "object",
            "properties": {
                "start_x": {"type": "integer"},
                "start_y": {"type": "integer"},
                "end_x": {"type": "integer"},
                "end_y": {"type": "integer"},
            },
            "required": ["start_x", "start_y", "end_x", "end_y"],
        },
    )

    log.info(
        "computer_use_tools_registered",
        tools=[
            "computer_screenshot",
            "computer_click",
            "computer_type",
            "computer_hotkey",
            "computer_scroll",
            "computer_drag",
        ],
    )
    return tools
