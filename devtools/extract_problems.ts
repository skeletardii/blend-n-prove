import * as fs from 'fs';
import * as path from 'path';

// Types for Tutorial Data
interface TutorialProblem {
  problem_number: number;
  difficulty: string;
  premises: string[];
  conclusion: string;
  solution: string;
}

interface TutorialData {
  rule_name: string;
  description: string;
  rule_pattern: string;
  tutorial_key: string;
  problems: TutorialProblem[];
}

// Types for Classic Data
interface ClassicProblem {
  premises: string[];
  conclusion: string;
  expected_operations: number;
  description: string;
  solution: string;
}

interface ClassicLevel {
  level: number;
  description: string;
  problems: ClassicProblem[];
}

// Tutorial keys from TutorialDataManager
const TUTORIAL_KEYS = [
  'modus-ponens',
  'modus-tollens',
  'hypothetical-syllogism',
  'disjunctive-syllogism',
  'simplification',
  'conjunction',
  'addition',
  'de-morgans-and',
  'de-morgans-or',
  'double-negation',
  'resolution',
  'biconditional',
  'distributivity',
  'commutativity',
  'associativity',
  'idempotent',
  'absorption',
  'negation-laws'
];

// Parse a tutorial markdown file
function parseTutorialMarkdown(content: string, tutorialKey: string): TutorialData {
  const lines = content.split('\n');
  const tutorial: TutorialData = {
    rule_name: '',
    description: '',
    rule_pattern: '',
    tutorial_key: tutorialKey,
    problems: []
  };

  let currentSection = '';
  let currentProblem: TutorialProblem | null = null;
  let currentField = '';
  let problemCount = 0;

  for (const line of lines) {
    const trimmed = line.trim();

    // Parse title (first line starting with #)
    if (trimmed.startsWith('# ') && !tutorial.rule_name) {
      tutorial.rule_name = trimmed.substring(2).trim();
      continue;
    }

    // Parse sections
    if (trimmed.startsWith('## Description')) {
      currentSection = 'description';
      continue;
    } else if (trimmed.startsWith('## Rule Pattern')) {
      currentSection = 'pattern';
      continue;
    } else if (trimmed.startsWith('## Problems')) {
      currentSection = 'problems';
      continue;
    }

    // Parse subsections (problems)
    if (trimmed.startsWith('### Problem')) {
      // Save previous problem if exists
      if (currentProblem) {
        tutorial.problems.push(currentProblem);
      }

      problemCount++;
      // Extract difficulty from parentheses
      let difficulty = 'Easy';
      if (trimmed.includes('(') && trimmed.includes(')')) {
        const start = trimmed.indexOf('(');
        const end = trimmed.indexOf(')');
        const diffText = trimmed.substring(start + 1, end);
        if (diffText.includes(':')) {
          difficulty = diffText.split(':')[1].trim();
        }
      }

      currentProblem = {
        problem_number: problemCount,
        difficulty,
        premises: [],
        conclusion: '',
        solution: ''
      };
      currentField = '';
      continue;
    }

    // Parse problem fields
    if (currentSection === 'problems' && currentProblem) {
      if (trimmed.startsWith('**Premises:**')) {
        currentField = 'premises';
        continue;
      } else if (trimmed.startsWith('**Conclusion:**')) {
        currentField = 'conclusion';
        continue;
      } else if (trimmed.startsWith('**Brief Solution:**')) {
        currentField = 'solution';
        continue;
      } else if (trimmed === '---' || trimmed === '') {
        currentField = '';
        continue;
      }

      // Add content to current field
      if (currentField === 'premises') {
        if (trimmed.startsWith('- ')) {
          currentProblem.premises.push(trimmed.substring(2).trim());
        }
      } else if (currentField === 'conclusion') {
        if (!trimmed.startsWith('**')) {
          currentProblem.conclusion = trimmed;
        }
      } else if (currentField === 'solution') {
        if (!trimmed.startsWith('**')) {
          currentProblem.solution = trimmed;
        }
      }
    }
    // Parse description
    else if (currentSection === 'description') {
      if (trimmed && !trimmed.startsWith('#')) {
        if (tutorial.description) {
          tutorial.description += ' ';
        }
        tutorial.description += trimmed;
      }
    }
    // Parse pattern
    else if (currentSection === 'pattern') {
      if (trimmed && !trimmed.startsWith('#')) {
        tutorial.rule_pattern = trimmed;
      }
    }
  }

  // Save last problem
  if (currentProblem) {
    tutorial.problems.push(currentProblem);
  }

  return tutorial;
}

// Classic mode order templates with generated solutions
const CLASSIC_LEVELS: ClassicLevel[] = [
  {
    level: 1,
    description: 'Level 1: 1 operation, max 2 premises',
    problems: [
      {
        premises: ['P → Q', 'P'],
        conclusion: 'Q',
        expected_operations: 1,
        description: 'Modus Ponens',
        solution: 'Apply Modus Ponens: from "P → Q" and "P", conclude "Q".'
      },
      {
        premises: ['P ∧ Q'],
        conclusion: 'P',
        expected_operations: 1,
        description: 'Simplification (left)',
        solution: 'Apply Simplification to extract the left conjunct "P" from "P ∧ Q".'
      },
      {
        premises: ['P → Q', '¬Q'],
        conclusion: '¬P',
        expected_operations: 1,
        description: 'Modus Tollens',
        solution: 'Apply Modus Tollens: from "P → Q" and "¬Q", conclude "¬P".'
      },
      {
        premises: ['P ∨ Q', '¬P'],
        conclusion: 'Q',
        expected_operations: 1,
        description: 'Disjunctive Syllogism',
        solution: 'Apply Disjunctive Syllogism: from "P ∨ Q" and "¬P", conclude "Q".'
      },
      {
        premises: ['¬¬P'],
        conclusion: 'P',
        expected_operations: 1,
        description: 'Double Negation',
        solution: 'Apply Double Negation elimination to remove "¬¬" and get "P".'
      },
      {
        premises: ['P', 'Q'],
        conclusion: 'P ∧ Q',
        expected_operations: 1,
        description: 'Conjunction',
        solution: 'Apply Conjunction to combine "P" and "Q" into "P ∧ Q".'
      },
      {
        premises: ['R ∧ S'],
        conclusion: 'S',
        expected_operations: 1,
        description: 'Simplification (right)',
        solution: 'Apply Simplification to extract the right conjunct "S" from "R ∧ S".'
      },
      {
        premises: ['¬(P ∧ Q)'],
        conclusion: '¬P ∨ ¬Q',
        expected_operations: 1,
        description: "De Morgan's Law (AND)",
        solution: 'Apply De Morgan\'s Law to transform "¬(P ∧ Q)" into "¬P ∨ ¬Q".'
      },
      {
        premises: ['¬(P ∨ Q)'],
        conclusion: '¬P ∧ ¬Q',
        expected_operations: 1,
        description: "De Morgan's Law (OR)",
        solution: 'Apply De Morgan\'s Law to transform "¬(P ∨ Q)" into "¬P ∧ ¬Q".'
      },
      {
        premises: ['Q ∨ R', '¬Q'],
        conclusion: 'R',
        expected_operations: 1,
        description: 'Disjunctive Syllogism (variant)',
        solution: 'Apply Disjunctive Syllogism: from "Q ∨ R" and "¬Q", conclude "R".'
      }
    ]
  },
  {
    level: 2,
    description: 'Level 2: 2 operations, 2-3 premises',
    problems: [
      {
        premises: ['P → Q', 'Q → R', 'P'],
        conclusion: 'R',
        expected_operations: 2,
        description: 'Hypothetical Syllogism + MP',
        solution: 'Apply Hypothetical Syllogism to get "P → R" from the first two premises, then Modus Ponens with "P" to get "R".'
      },
      {
        premises: ['P ∧ Q', 'R'],
        conclusion: 'P ∧ R',
        expected_operations: 2,
        description: 'Simplification + Conjunction',
        solution: 'Apply Simplification to extract "P" from "P ∧ Q", then Conjunction to combine "P" and "R".'
      },
      {
        premises: ['¬¬P', 'P → Q'],
        conclusion: 'Q',
        expected_operations: 2,
        description: 'Double Negation + Modus Ponens',
        solution: 'Apply Double Negation to get "P" from "¬¬P", then Modus Ponens with "P → Q" to get "Q".'
      },
      {
        premises: ['P ∨ Q', '¬P', 'Q → R'],
        conclusion: 'R',
        expected_operations: 2,
        description: 'Disjunctive Syllogism + MP',
        solution: 'Apply Disjunctive Syllogism to get "Q" from "P ∨ Q" and "¬P", then Modus Ponens with "Q → R" to get "R".'
      },
      {
        premises: ['P ∧ (Q ∧ R)'],
        conclusion: 'Q ∧ R',
        expected_operations: 2,
        description: 'Simplification + Simplification',
        solution: 'Apply Simplification twice: first to extract "Q ∧ R" from the outer conjunction, then you already have the result.'
      },
      {
        premises: ['¬(P ∨ Q)', 'R → S'],
        conclusion: '¬P ∧ ¬Q',
        expected_operations: 2,
        description: "De Morgan's + ignore unused premise",
        solution: 'Apply De Morgan\'s Law to "¬(P ∨ Q)" to get "¬P ∧ ¬Q". The premise "R → S" is not needed.'
      },
      {
        premises: ['P', 'Q', 'R'],
        conclusion: '(P ∧ Q) ∧ R',
        expected_operations: 2,
        description: 'Conjunction + Conjunction',
        solution: 'Apply Conjunction to combine "P" and "Q" into "P ∧ Q", then apply Conjunction again with "R".'
      },
      {
        premises: ['P → (Q ∧ R)', 'P'],
        conclusion: 'Q',
        expected_operations: 2,
        description: 'Modus Ponens + Simplification',
        solution: 'Apply Modus Ponens to get "Q ∧ R", then Simplification to extract "Q".'
      },
      {
        premises: ['(P ∧ Q) → R', 'P', 'Q'],
        conclusion: 'R',
        expected_operations: 2,
        description: 'Conjunction + Modus Ponens',
        solution: 'Apply Conjunction to combine "P" and "Q" into "P ∧ Q", then Modus Ponens to get "R".'
      },
      {
        premises: ['P ∨ (Q ∧ R)', '¬P'],
        conclusion: 'Q ∧ R',
        expected_operations: 2,
        description: 'Disjunctive Syllogism + identity',
        solution: 'Apply Disjunctive Syllogism: from "P ∨ (Q ∧ R)" and "¬P", conclude "Q ∧ R".'
      }
    ]
  },
  {
    level: 3,
    description: 'Level 3: 3 operations, 3-4 premises',
    problems: [
      {
        premises: ['P → Q', 'Q → R', 'R → S', 'P'],
        conclusion: 'S',
        expected_operations: 3,
        description: 'Chain of Hypothetical Syllogisms',
        solution: 'Apply Hypothetical Syllogism twice to build "P → S", then Modus Ponens with "P" to get "S".'
      },
      {
        premises: ['P ∧ Q', 'R ∧ S'],
        conclusion: 'P ∧ R',
        expected_operations: 3,
        description: 'Multiple Simplifications + Conjunction',
        solution: 'Apply Simplification to extract "P" from "P ∧ Q" and "R" from "R ∧ S", then Conjunction to combine them.'
      },
      {
        premises: ['¬¬(P ∨ Q)', '¬P', 'Q → R'],
        conclusion: 'R',
        expected_operations: 3,
        description: 'Double Neg + Disj Syll + MP',
        solution: 'Apply Double Negation to get "P ∨ Q", then Disjunctive Syllogism with "¬P" to get "Q", finally Modus Ponens to get "R".'
      },
      {
        premises: ['(P ∧ Q) → R', '¬R', 'P'],
        conclusion: '¬Q',
        expected_operations: 3,
        description: "Modus Tollens + De Morgan's + Disj Syll",
        solution: 'Apply Modus Tollens to get "¬(P ∧ Q)", then De Morgan\'s to get "¬P ∨ ¬Q", finally Disjunctive Syllogism with "P" to get "¬Q".'
      },
      {
        premises: ['P ∨ (Q ∧ R)', '¬P'],
        conclusion: 'Q',
        expected_operations: 3,
        description: 'Disjunctive Syllogism + Simplification',
        solution: 'Apply Disjunctive Syllogism to get "Q ∧ R", then Simplification to extract "Q".'
      },
      {
        premises: ['¬(P ∧ Q)', 'R → P', 'R'],
        conclusion: '¬Q',
        expected_operations: 3,
        description: "MP + De Morgan's + Disj Syll",
        solution: 'Apply Modus Ponens to get "P", then De Morgan\'s on "¬(P ∧ Q)" to get "¬P ∨ ¬Q", finally Disjunctive Syllogism to get "¬Q".'
      },
      {
        premises: ['P', 'Q', 'R', 'S'],
        conclusion: '((P ∧ Q) ∧ R) ∧ S',
        expected_operations: 3,
        description: 'Chain of Conjunctions',
        solution: 'Apply Conjunction three times: combine "P" and "Q", then combine with "R", finally combine with "S".'
      },
      {
        premises: ['P → (Q ∨ R)', 'P', '¬Q'],
        conclusion: 'R',
        expected_operations: 3,
        description: 'MP + Disjunctive Syllogism',
        solution: 'Apply Modus Ponens to get "Q ∨ R", then Disjunctive Syllogism with "¬Q" to get "R".'
      },
      {
        premises: ['¬¬P ∧ ¬¬Q'],
        conclusion: 'P ∧ Q',
        expected_operations: 3,
        description: 'Simplification + Double Neg + Conjunction',
        solution: 'Apply Simplification to get "¬¬P" and "¬¬Q", then Double Negation on each to get "P" and "Q", finally Conjunction.'
      },
      {
        premises: ['(P ∨ Q) ∧ R', '¬P'],
        conclusion: 'Q ∧ R',
        expected_operations: 3,
        description: 'Simplification + Disj Syll + Conjunction',
        solution: 'Apply Simplification to get "P ∨ Q" and "R", then Disjunctive Syllogism to get "Q", finally Conjunction with "R".'
      }
    ]
  },
  {
    level: 4,
    description: 'Level 4: 3-4 operations, 4-5 premises',
    problems: [
      {
        premises: ['P → Q', 'Q → (R ∧ S)', 'R → T', 'P'],
        conclusion: 'T',
        expected_operations: 4,
        description: 'Complex chain with branching',
        solution: 'Chain the implications: Modus Ponens to get "Q", then "R ∧ S", extract "R" via Simplification, then Modus Ponens to get "T".'
      },
      {
        premises: ['¬(P ∨ Q)', 'R ∧ S'],
        conclusion: '¬P ∧ S',
        expected_operations: 4,
        description: "De Morgan's + Simplification + Conjunction",
        solution: 'Apply De Morgan\'s to get "¬P ∧ ¬Q", extract "¬P", extract "S" from "R ∧ S", then combine with Conjunction.'
      },
      {
        premises: ['P ∨ (Q ∧ R)', '¬P', 'S ∨ T', '¬S'],
        conclusion: 'Q ∧ T',
        expected_operations: 4,
        description: 'Multiple Disjunctive Syllogisms',
        solution: 'Apply Disjunctive Syllogism twice: get "Q ∧ R" and "T", then extract "Q" and combine with "T" via Conjunction.'
      },
      {
        premises: ['(P ∧ Q) → (R ∨ S)', 'P', 'Q', '¬R'],
        conclusion: 'S',
        expected_operations: 4,
        description: 'Conjunction + MP + Disj Syll',
        solution: 'Combine "P" and "Q" via Conjunction, apply Modus Ponens to get "R ∨ S", then Disjunctive Syllogism with "¬R" to get "S".'
      },
      {
        premises: ['¬¬(P → Q)', '¬¬P', 'Q → (R ∧ S)'],
        conclusion: 'R',
        expected_operations: 4,
        description: 'Double Neg + MP + MP + Simplification',
        solution: 'Apply Double Negation twice to get "P → Q" and "P", then chain Modus Ponens to get "R ∧ S", finally extract "R".'
      },
      {
        premises: ['P ∨ Q', '¬P', 'Q → R', 'R → S', 'S → T'],
        conclusion: 'T',
        expected_operations: 4,
        description: 'Disj Syll + Chain of MPs',
        solution: 'Get "Q" via Disjunctive Syllogism, then chain Modus Ponens through "R", "S", to "T".'
      },
      {
        premises: ['P → Q', 'Q → R', '¬R', 'P'],
        conclusion: '⊥',
        expected_operations: 4,
        description: 'Contradiction via MT',
        solution: 'Chain the implications to get "P → R", use Modus Tollens with "¬R" to get "¬P", which contradicts "P".'
      },
      {
        premises: ['(P ∨ Q) ∧ (R ∨ S)', '¬P', '¬R'],
        conclusion: 'Q ∧ S',
        expected_operations: 4,
        description: 'Multiple simplifications + syllogisms',
        solution: 'Extract "P ∨ Q" and "R ∨ S" via Simplification, then apply Disjunctive Syllogism twice to get "Q" and "S", combine via Conjunction.'
      },
      {
        premises: ['P → (Q → R)', 'P', 'Q', 'R → S'],
        conclusion: 'S',
        expected_operations: 4,
        description: 'Nested implications + chain',
        solution: 'Apply Modus Ponens to get "Q → R", then Modus Ponens with "Q" to get "R", finally Modus Ponens with "R → S" to get "S".'
      },
      {
        premises: ['¬(P ∨ Q) ∧ ¬(R ∨ S)'],
        conclusion: '¬P ∧ ¬R',
        expected_operations: 4,
        description: "Complex De Morgan's + Simplifications",
        solution: 'Apply Simplification to separate conjuncts, then De Morgan\'s on each to get "¬P ∧ ¬Q" and "¬R ∧ ¬S", extract "¬P" and "¬R", combine via Conjunction.'
      }
    ]
  },
  {
    level: 5,
    description: 'Level 5: 4+ operations, 4-6 premises',
    problems: [
      {
        premises: ['P → (Q ∧ R)', 'Q → S', 'R → T', 'P'],
        conclusion: 'S ∧ T',
        expected_operations: 5,
        description: 'Complex branching chain',
        solution: 'Apply Modus Ponens to get "Q ∧ R", extract "Q" and "R", apply Modus Ponens to each to get "S" and "T", combine via Conjunction.'
      },
      {
        premises: ['(P ∨ Q) → R', 'P', '¬R'],
        conclusion: '⊥',
        expected_operations: 5,
        description: 'Simple contradiction',
        solution: 'Use Addition to get "P ∨ Q" from "P", apply Modus Ponens to get "R", which contradicts "¬R".'
      },
      {
        premises: ['(P ∧ Q) → (R ∨ S)', '(R ∨ S) → T', 'P', 'Q'],
        conclusion: 'T',
        expected_operations: 5,
        description: 'Chain of implications',
        solution: 'Combine "P" and "Q", apply Modus Ponens to get "R ∨ S", then Modus Ponens again to get "T".'
      },
      {
        premises: ['P ∨ Q', '¬P ∨ R', '¬Q ∨ R'],
        conclusion: 'R',
        expected_operations: 5,
        description: 'Resolution-style proof',
        solution: 'Apply Resolution techniques: from the three disjunctions, deduce that "R" must be true through case analysis.'
      },
      {
        premises: ['(P → Q) ∧ (R → S)', '¬Q ∨ ¬S', 'P ∨ R'],
        conclusion: '¬P ∨ ¬R',
        expected_operations: 5,
        description: 'Complex Modus Tollens',
        solution: 'Extract the implications, use De Morgan\'s logic with "¬Q ∨ ¬S" to derive that at least one antecedent must be false.'
      },
      {
        premises: ['P ↔ Q', 'Q → (R ∧ S)', 'R → T', 'S → T', 'P'],
        conclusion: 'T',
        expected_operations: 5,
        description: 'Biconditional elimination + convergence',
        solution: 'Use Biconditional to get "Q", apply Modus Ponens to get "R ∧ S", extract either "R" or "S", then Modus Ponens to get "T".'
      },
      {
        premises: ['¬¬(P ∧ Q)', 'P → R', 'Q → S'],
        conclusion: 'R ∧ S',
        expected_operations: 5,
        description: 'Double negation + parallel inference',
        solution: 'Apply Double Negation to get "P ∧ Q", extract "P" and "Q", apply Modus Ponens to each to get "R" and "S", combine via Conjunction.'
      },
      {
        premises: ['P → Q', 'R → S', '(Q ∧ S) → T', 'P', 'R'],
        conclusion: 'T',
        expected_operations: 5,
        description: 'Convergent proof',
        solution: 'Apply Modus Ponens twice to get "Q" and "S", combine via Conjunction, then Modus Ponens to get "T".'
      },
      {
        premises: ['(P ∨ Q) → (R ∧ S)', 'P', '¬R → T', '¬T'],
        conclusion: 'R ∧ S',
        expected_operations: 5,
        description: 'Proof by contradiction',
        solution: 'Use Addition to get "P ∨ Q", apply Modus Ponens to get "R ∧ S". The premises about "T" help verify "R" must be true.'
      },
      {
        premises: ['P ⊕ Q', 'P → R', 'Q → R'],
        conclusion: 'R',
        expected_operations: 5,
        description: 'XOR elimination to common conclusion',
        solution: 'XOR means exactly one of "P" or "Q" is true. Either way, both lead to "R" via Modus Ponens, so "R" must be true.'
      }
    ]
  }
];

// Extract tutorials
function extractTutorials(): void {
  console.log('Extracting tutorial problems...');
  const docsDir = path.join(__dirname, '..', 'docs', 'game');
  const outputDir = path.join(__dirname, '..', 'data', 'tutorial');

  // Ensure output directory exists
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  let totalProblems = 0;

  for (const tutorialKey of TUTORIAL_KEYS) {
    const filePath = path.join(docsDir, `${tutorialKey}.md`);

    if (!fs.existsSync(filePath)) {
      console.warn(`Warning: Tutorial file not found: ${filePath}`);
      continue;
    }

    const content = fs.readFileSync(filePath, 'utf-8');
    const tutorial = parseTutorialMarkdown(content, tutorialKey);

    const outputPath = path.join(outputDir, `${tutorialKey}.json`);
    fs.writeFileSync(outputPath, JSON.stringify(tutorial, null, 2), 'utf-8');

    console.log(`✓ Extracted ${tutorial.rule_name}: ${tutorial.problems.length} problems`);
    totalProblems += tutorial.problems.length;
  }

  console.log(`\nTotal tutorial problems extracted: ${totalProblems}`);
}

// Extract classic mode problems
function extractClassicProblems(): void {
  console.log('\nExtracting classic mode problems...');
  const outputDir = path.join(__dirname, '..', 'data', 'classic');

  // Ensure output directory exists
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  let totalProblems = 0;

  for (const level of CLASSIC_LEVELS) {
    const outputPath = path.join(outputDir, `level-${level.level}.json`);
    fs.writeFileSync(outputPath, JSON.stringify(level, null, 2), 'utf-8');

    console.log(`✓ Extracted Level ${level.level}: ${level.problems.length} problems`);
    totalProblems += level.problems.length;
  }

  console.log(`\nTotal classic problems extracted: ${totalProblems}`);
}

// Main execution
function main(): void {
  console.log('=== Problem Extraction Tool ===\n');

  extractTutorials();
  extractClassicProblems();

  console.log('\n=== Extraction Complete ===');
  console.log('Tutorial files written to: data/tutorial/');
  console.log('Classic files written to: data/classic/');
}

main();
