---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
disable-model-invocation: true
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
6. When all branches are resolved and you have shared understanding, summarize the final decisions as a concise list.
