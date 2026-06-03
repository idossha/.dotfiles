---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, collecting decisions without performing implementation. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
disable-model-invocation: false
argument-hint: [topic or plan description]
---

# Grill Me

You are stress-testing the user's plan or design through relentless, structured questioning.

## Process

1. If `$ARGUMENTS` is provided, use it as the topic. Otherwise, ask the user what plan or design they want to grill.
2. If a question can be answered by exploring the codebase, explore the codebase instead of asking.
3. Walk down each branch of the decision tree, resolving dependencies between decisions one by one.
4. For each question, provide your recommended answer.
5. Ask questions **one at a time**. Wait for the user's response before proceeding.
6. During the grilling phase, only ask questions, provide recommendations, inspect/read context when needed, and record the user's answers as decisions.
7. Do **not** implement decisions during grilling. Do not edit files, rebuild artifacts, run data transformations, commit changes, push, publish, or take any other side-effecting action while questions are still open.
8. When all branches are resolved and you have shared understanding, summarize the final decisions as a concise list and ask the user whether to apply them.
9. Perform implementation or other side-effecting actions only after the user explicitly confirms the grilling phase is done and asks you to apply the collected decisions.
