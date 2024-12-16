
#!/bin/bash

# aerospace.sh

sketchybar --add event aerospace_workspace_change

for sid in $(aerospace list-workspaces --all); do
    # Check if item already exists (requires SketchyBar 1.8.0+)
    if ! sketchybar --query space.$sid &> /dev/null; then
        # Item doesn't exist, add it
        sketchybar --add item space.$sid left \
            --subscribe space.$sid aerospace_workspace_change \
            --set space.$sid \
                background.color=0x44ffffff \
                background.corner_radius=5 \
                background.height=20 \
                background.drawing=off \
                label="$sid" \
                padding_left=10 \
                padding_right=10 \
                click_script="aerospace workspace $sid" \
                script="$CONFIG_DIR/plugins/aerospace.sh $sid"
    else
        # Item exists, update its properties if needed
        sketchybar --set space.$sid \
            background.color=0x44ffffff \
            background.corner_radius=5 \
            background.height=20 \
            background.drawing=off \
            label="$sid" \
            padding_left=10 \
            padding_right=10 \
            click_script="aerospace workspace $sid" \
            script="$CONFIG_DIR/plugins/aerospace.sh $sid"
    fi
done

