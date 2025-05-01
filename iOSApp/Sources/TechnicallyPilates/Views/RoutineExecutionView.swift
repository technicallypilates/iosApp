let samplePoses = [
    Pose(
        name: "Plank",
        description: "A fundamental core strengthening exercise",
        category: "Core",
        difficulty: 2,
        instructions: ["Start in a push-up position", "Keep your body in a straight line", "Hold the position"],
        benefits: ["Strengthens core muscles", "Improves posture", "Builds stability"],
        modifications: ["Drop to knees for modified plank", "Perform on forearms instead of hands"],
        contraindications: ["Wrist injuries", "Lower back pain"],
        duration: 60,
        repetitions: 1
    ),
    Pose(
        name: "Push-up",
        description: "Classic upper body strength exercise",
        category: "Upper Body",
        difficulty: 3,
        instructions: ["Start in plank position", "Lower body with control", "Push back up"],
        benefits: ["Builds chest strength", "Strengthens shoulders", "Improves core stability"],
        modifications: ["Perform on knees", "Incline push-ups on elevated surface"],
        contraindications: ["Shoulder injuries", "Wrist pain"],
        duration: 30,
        repetitions: 10
    )
]

let pose = Pose(
    name: "Plank",
    description: "Hold a plank position",
    category: "Core",
    difficulty: 2,
    instructions: ["Start in a push-up position", "Keep your body straight", "Hold for the duration"],
    benefits: ["Strengthens core", "Improves posture", "Builds endurance"],
    modifications: ["Drop to knees", "Use elbows instead of hands"],
    contraindications: ["Wrist issues", "Shoulder problems"],
    duration: 60,
    repetitions: 1
) 