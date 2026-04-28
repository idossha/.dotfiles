---
name: pyside6-napari
description: PySide6 and napari GUI development patterns. Use when building or modifying Qt-based GUIs with napari viewers for medical image visualization.
user-invocable: false
---

# PySide6 + napari GUI Patterns

## Widget Structure
```python
from PySide6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QLabel
from PySide6.QtCore import Qt, Signal, Slot, QTimer

class MyPanel(QWidget):
    value_changed = Signal(int)  # Class-level signal declaration

    def __init__(self, parent=None):
        super().__init__(parent)
        self._setup_ui()
        self._connect_signals()

    def _setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(8, 8, 8, 8)
        layout.setSpacing(4)
        self.button = QPushButton("Action")
        layout.addWidget(self.button)

    def _connect_signals(self):
        self.button.clicked.connect(self._on_click)

    @Slot()
    def _on_click(self):
        self.value_changed.emit(42)
```

## Signal/Slot Rules
- Declare signals at **class level**, never in `__init__`
- Use `@Slot()` decorator on receiver methods
- **blockSignals(True)** when programmatically updating widgets to prevent feedback loops:
  ```python
  self.spinbox.blockSignals(True)
  self.spinbox.setValue(new_value)
  self.spinbox.blockSignals(False)
  ```
- Disconnect before reconnecting to prevent duplicate handlers
- Use signal bus pattern (single QObject hub) for cross-widget communication — never widget-to-widget

## Layout Patterns
```python
# Scrollable sidebar
scroll = QScrollArea()
scroll.setWidgetResizable(True)
scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
content = QWidget()
scroll.setWidget(content)

# Resizable split
splitter = QSplitter(Qt.Horizontal)
splitter.addWidget(viewer)
splitter.addWidget(sidebar)
splitter.setSizes([800, 300])

# Grid form
grid = QGridLayout()
grid.addWidget(QLabel("Model:"), 0, 0)
grid.addWidget(combo, 0, 1)
```

## napari in PySide6

### Embedding
```python
import napari

viewer = napari.Viewer(show=False)
qt_widget = viewer.window._qt_window
layout.addWidget(qt_widget)
```

### Image Layers
```python
# T1w MRI
layer = viewer.add_image(
    data, name="T1w", colormap="gray",
    contrast_limits=(0, 2000), gamma=0.7,
    affine=affine_4x4,
)

# CT overlay
ct_layer = viewer.add_image(
    ct_data, name="CT", colormap="gray",
    contrast_limits=(-100, 3000),
    blending="additive", opacity=0.5,
)
```

### Points (Electrode Contacts)
```python
points = viewer.add_points(
    positions,  # (N, 3) array
    name="electrode_label",
    face_color=color_tuple,
    size=3, symbol="disc", edge_width=0,
)
# Update dynamically
points.data = new_positions
points.face_color = new_colors
```

### Mouse Events
```python
@layer.mouse_drag_callbacks.append
def on_click(layer, event):
    coords = layer.world_to_data(event.position)
    if all(0 <= c < s for c, s in zip(coords, data.shape)):
        voxel = np.round(coords).astype(int)
```

### Multi-Panel Sync
```python
# Sync slice positions across viewers
def sync_slices(event):
    source = event.source
    for v in other_viewers:
        v.dims.set_point(axis, source.dims.point[axis])
```

## napari-Compatible Dark Theme
```python
DARK_BG = "#262930"
DARK_SURFACE = "#2e3138"
DARK_TEXT = "#d6d6d6"
DARK_ACCENT = "#4e9ff5"
DARK_BORDER = "#414751"

widget.setStyleSheet(f"""
    QWidget {{ background-color: {DARK_BG}; color: {DARK_TEXT}; }}
    QPushButton {{
        background-color: {DARK_SURFACE};
        border: 1px solid {DARK_BORDER};
        padding: 4px 12px; border-radius: 3px;
    }}
    QPushButton:hover {{ background-color: {DARK_ACCENT}; }}
    QGroupBox {{ border: 1px solid {DARK_BORDER}; margin-top: 8px; }}
    QGroupBox::title {{ color: {DARK_ACCENT}; }}
""")
```

## Performance
- `QTimer.singleShot(0, callback)` — defer heavy UI updates to avoid blocking
- Debounce `viewer.dims.events.current_step` for expensive slice-change handlers
- `rendering='attenuated_mip'` is GPU-friendly for large volumes
- Always close napari viewers properly to release GPU resources
- Profile rendering: `napari.utils.perf`

## State Management (IDOsEEG pattern)
```
User Action → SignalBus.signal.emit() → Command.execute() → AppState.update() → Widget.refresh()
                                              ↕
                                      CommandHistory (undo/redo stacks)
```
- **SignalBus**: Single QObject with all cross-widget signals
- **AppState**: Mutable state holder (session, volumes, tool, selection)
- **CommandHistory**: Undo/redo with concrete command classes
- Widgets subscribe to SignalBus, read from AppState, NEVER talk directly to each other
