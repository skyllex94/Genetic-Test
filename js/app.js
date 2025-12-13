function dragEnter(e) {
  e.preventDefault();
  this.classList.add("hovered");
}

function dragLeave() {
  this.className = "placeholder empty";
}

function dragDrop() {
  this.className = "placeholder empty";
}

// ---- Contact form Validation ----
function validateForm() {
  var name = document.getElementById("name").value;
  if (name == "") {
    console.log("Your name is blank");
    document.querySelector(".status").innerHTML =
      "Името не може да бъде празно";
    return false;
  }
  var email = document.getElementById("email").value;
  if (email == "") {
    document.querySelector(".status").innerHTML =
      "Имейла не може да бъде празно";
    return false;
  } else {
    var re =
      /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    if (!re.test(email)) {
      document.querySelector(".status").innerHTML = "Имейла не е валиден";
      return false;
    }
  }
  var subject = document.getElementById("subject").value;
  if (subject == "") {
    document.querySelector(".status").innerHTML =
      "Заглавието не може да бъде празно";
    return false;
  }
  var message = document.getElementById("message").value;
  if (message == "") {
    document.querySelector(".status").innerHTML =
      "Cъобщението не може да бъде празно";
    return false;
  }
  document.querySelector(".status").innerHTML = "Изпращане...";
}

//  ---- Draggable objects ----

function allowDrop(ev) {
  ev.preventDefault();
}

function drag(ev) {
  // Set the item being dragged to a form of a variable
  ev.dataTransfer.setData("item", ev.target.id);
  // UI Manipulation - NodeList of all the placeholders
  const empties = document.querySelectorAll(".empty");

  for (const empty of empties) {
    // Hovering change when the dragged item in on top
    empty.addEventListener("dragover", function dragOver(e) {
      e.preventDefault();
      empty.classList.add("hovered");
    });
    empty.addEventListener("dragenter", dragEnter);
    empty.addEventListener("dragleave", dragLeave);
    empty.addEventListener("drop", dragDrop);
  }
}

function drop(ev) {
  ev.preventDefault();

  // Fetch the data from the item being dragged
  let data = ev.dataTransfer.getData("item");
  // Store the source and the target of the drag
  let src = document.getElementById(data);
  let target = ev.currentTarget.firstElementChild;

  // Check if there is a dropped item on the target already
  if (target == null) {
    // If not, create a copy of the sourse item being dragged
    let clone = src.cloneNode(true);
    clone.id = document.getElementById(data).id + "1";
    // Add a class of choice so it can be error checked later
    clone.classList.add("choice");
    ev.target.appendChild(clone);
  } else {
    let parent = src.parentNode;
    // check if the drag is asked from a finger rather than the symbol type
    if (
      parent.classList.contains("placeholder") ||
      (parent.classList.contains("symbol") &&
        target.parentNode.classList.contains("symbol"))
    ) {
      return 1;
    } else {
      // Replace the placeholder with the new symbol being dragged
      let clone = src.cloneNode(true);
      ev.currentTarget.replaceChild(clone, target);
    }
  }
}

//  ---- Confirm selection with fingerprint data collected from the online form  ----
function confirmData() {
  // All fingers selection
  let leftHandThumb = document.getElementById("left-thumb").firstElementChild;
  let leftHandIndex = document.getElementById("left-index").firstElementChild;
  let leftHandMiddle = document.getElementById("left-middle").firstElementChild;
  let leftHandRing = document.getElementById("left-ring").firstElementChild;
  let leftHandPinky = document.getElementById("left-pinky").firstElementChild;

  let rightHandThumb = document.getElementById("right-thumb").firstElementChild;
  let rightHandIndex = document.getElementById("right-index").firstElementChild;
  let rightHandMiddle =
    document.getElementById("right-middle").firstElementChild;
  let rightHandRing = document.getElementById("right-ring").firstElementChild;
  let rightHandPinky = document.getElementById("right-pinky").firstElementChild;

  // All symbols selection
  let spiral = document.getElementById("drag_spiral");
  let doubleSpiral = document.getElementById("drag_double_spiral");
  let rainbow = document.getElementById("drag_rainbow");
  let rKnot = document.getElementById("drag_r_knot");
  let lKnot = document.getElementById("drag_l_knot");
  let tent = document.getElementById("drag_tent");

  // Arrays of all the symbols and fingers
  let arrFingers = [
    leftHandThumb,
    leftHandIndex,
    leftHandMiddle,
    leftHandRing,
    leftHandPinky,
    rightHandThumb,
    rightHandIndex,
    rightHandMiddle,
    rightHandRing,
    rightHandPinky,
  ];
  let arrSymbols = [spiral, doubleSpiral, rainbow, rKnot, lKnot, tent];

  let age = document.getElementById("age").value;
  if (age > 99) {
    alert("Моля прегледайте годините си.");
    return 1;
  }

  let select = document.getElementById("gender");
  let gender = select.options[select.selectedIndex].text;

  if (
    leftHandThumb &&
    leftHandIndex &&
    leftHandMiddle &&
    leftHandRing &&
    leftHandPinky &&
    rightHandThumb &&
    rightHandIndex &&
    rightHandMiddle &&
    rightHandRing &&
    rightHandPinky != null
  ) {
    // Creating an objects with key-value pairs of all the fingers with their chosen symbol
    // When a symbol is dropped, it adds a "choice" class to be further fetched for the email body
    allChoicesEmailMessage = {}; // {"Ляв Палец" : "Двойна Спирала", "Ляв Показалец" : ...}
    let choices = document.querySelectorAll(".choice");
    let fingers = document.querySelectorAll(".finger");

    // Looping through each one and assigning them values
    for (let i = 0; i < choices.length; i++) {
      allChoicesEmailMessage[fingers[i].id] = choices[i].name;
    }

    // Creating arrays of the keys and values in order to format it for the email body
    arrKeys = [];
    arrValues = [];
    arrKeys = Object.keys(allChoicesEmailMessage);
    arrValues = Object.values(allChoicesEmailMessage);

    // Email Body Header - using html tags for line breaks
    let emailBody = "Пол: " + gender + "\n";
    emailBody += "\n" + " --- Пръстови отпечатъци ---" + "\n" + "\n";

    // Loop through each key-value and format it as you include it to the email body
    for (let i = 0; i < arrKeys.length; i++) {
      emailBody += arrKeys[i] + " : " + arrValues[i] + "\n";
    }

    // Save data to localStorage for the report page
    localStorage.setItem('report_name', document.getElementById("name").value);
    localStorage.setItem('report_gender', gender);
    localStorage.setItem('report_age', age);

    // Save fingerprint data
    const fingerprintData = {
      leftHand: [
        arrFingers[0] ? arrFingers[0].name : 'Не е посочен',
        arrFingers[1] ? arrFingers[1].name : 'Не е посочен',
        arrFingers[2] ? arrFingers[2].name : 'Не е посочен',
        arrFingers[3] ? arrFingers[3].name : 'Не е посочен',
        arrFingers[4] ? arrFingers[4].name : 'Не е посочен'
      ],
      rightHand: [
        arrFingers[5] ? arrFingers[5].name : 'Не е посочен',
        arrFingers[6] ? arrFingers[6].name : 'Не е посочен',
        arrFingers[7] ? arrFingers[7].name : 'Не е посочен',
        arrFingers[8] ? arrFingers[8].name : 'Не е посочен',
        arrFingers[9] ? arrFingers[9].name : 'Не е посочен'
      ]
    };
    localStorage.setItem('fingerprint_data', JSON.stringify(fingerprintData));

    // Populate the hidden textarea with the selection
    let message = document.getElementById("message");
    message.value = emailBody;

    // UI Buttons Handling
    document.getElementById("sendData").disabled = false;
    document.getElementById("confirmSelection").disabled = true;

    // Disable dragging
    arrSymbols.forEach((symbol) => symbol.setAttribute("draggable", false));
    arrFingers.forEach((finger) => {
      finger.setAttribute("draggable", false);
      finger.parentElement.parentElement.parentElement.classList.replace(
        "border-dark",
        "confirmed"
      );
    });

    // Redirect to report page after a short delay
    setTimeout(() => {
      window.location.href = 'report.html';
    }, 1000);
  } else {
    alert("Моля въведете нужната информация във всички полета.");
  }
}

// ---- Response back from Elastic Email promise which will give a conditional alert message ----
function emailResponse(message) {
  if (message == "OK") {
    return alert(
      "Вашите резултати бяха изпратени към нас. Ще ви върнем отговор в следващите няколко дни. Благодарим Ви!"
    );
  } else {
    return alert(
      "Грешка с изпращането, моля проверете дали всички папили са въведели, ако грешката продължава свържете се с нас чрез контактната форма."
    );
  }
}

function down() {
  document.getElementById("download").click();
}

// Mobile Functionality
function mobileConfirm() {
  // Confirm user choice
  if (
    confirm("Сигурни ли сте, че проверихте всеки един от вашите пръсти?") ==
    false
  ) {
    return 1;
  }

  // Define all finger selections
  let leftThumb = document.getElementById("mobile-left-thumb");
  let leftIndex = document.getElementById("mobile-left-index");
  let leftMiddle = document.getElementById("mobile-left-middle");
  let leftRing = document.getElementById("mobile-left-ring");
  let leftPinky = document.getElementById("mobile-left-pinky");

  let rightThumb = document.getElementById("mobile-right-thumb");
  let rightIndex = document.getElementById("mobile-right-index");
  let rightMiddle = document.getElementById("mobile-right-middle");
  let rightRing = document.getElementById("mobile-right-ring");
  let rightPinky = document.getElementById("mobile-right-pinky");

  // Array of all of them for iteration
  let allFingers = [
    leftThumb,
    leftIndex,
    leftMiddle,
    leftRing,
    leftPinky,
    rightThumb,
    rightIndex,
    rightMiddle,
    rightRing,
    rightPinky,
  ];

  let age = document.getElementById("age").value;
  if (age > 99) {
    alert("Моля прегледайте годините си.");
    return 1;
  }

  // Gender Selection
  let select = document.getElementById("gender");
  let gender = select.options[select.selectedIndex].text;

  // Email Body Creation
  let emailBody = "Пол: " + gender + "\n";
  emailBody += "\n" + "--- Пръстови отпечатъци ---" + "\n" + "\n";

  // Getting the info for each finger choices and adding to the email body
  for (finger of allFingers) {
    // Looping over all of the finger selections and adding their
    // symbol and finger to the email body
    let fingerName = finger.parentElement.id;
    emailBody += fingerName + ": ";
    let symbol = finger.options[finger.selectedIndex].text;
    emailBody += symbol + "\n";
  }

  // Save data to localStorage for the report page
  localStorage.setItem('report_name', document.getElementById("name").value);
  localStorage.setItem('report_gender', gender);
  localStorage.setItem('report_age', age);

  // Save fingerprint data for mobile
  const fingerprintData = {
    leftHand: [],
    rightHand: []
  };

  // Get mobile finger selections
  const leftFingers = ['mobile-left-thumb', 'mobile-left-index', 'mobile-left-middle', 'mobile-left-ring', 'mobile-left-pinky'];
  const rightFingers = ['mobile-right-thumb', 'mobile-right-index', 'mobile-right-middle', 'mobile-right-ring', 'mobile-right-pinky'];

  leftFingers.forEach(fingerId => {
    const element = document.getElementById(fingerId);
    const value = element.options[element.selectedIndex].text;
    fingerprintData.leftHand.push(value);
  });

  rightFingers.forEach(fingerId => {
    const element = document.getElementById(fingerId);
    const value = element.options[element.selectedIndex].text;
    fingerprintData.rightHand.push(value);
  });

  localStorage.setItem('fingerprint_data', JSON.stringify(fingerprintData));

  let message = document.getElementById("message");
  message.value = emailBody;

  // UI button disabling and finger selection
  document.getElementById("sendData").disabled = false;
  document.getElementById("confirmSelection").disabled = true;
  disableFingerSelections(allFingers);

  // Redirect to report page after a short delay
  setTimeout(() => {
    window.location.href = 'report.html';
  }, 1000);
}

function disableFingerSelections(fingers) {
  // Disabling every selections HTML element
  for (finger of fingers) {
    finger.disabled = true;
  }
}

// ===== ДЕРМАТОГЛИФИЧНИ АНАЛИЗИ =====

// Система за оценка на пръстовите отпечатъци
const FINGERPRINT_SCORES = {
  'Дъга': 0,
  'Палатковидна Дъга': 0,
  'L-Примка': 1,
  'R-Примка': 1,
  'Спирала': 2,
  'Двойна Спирала': 2
};

// Изчисляване на общата дерматоглифична формула
function calculateDermatoglyphicFormula(fingerprints) {
  let totalScore = 0;
  let leftHandScore = 0;
  let rightHandScore = 0;

  // Лява ръка
  const leftFingers = ['left-thumb', 'left-index', 'left-middle', 'left-ring', 'left-pinky'];
  leftFingers.forEach(finger => {
    const score = FINGERPRINT_SCORES[fingerprints.leftHand[leftFingers.indexOf(finger)]] || 0;
    leftHandScore += score;
    totalScore += score;
  });

  // Дясна ръка
  const rightFingers = ['right-thumb', 'right-index', 'right-middle', 'right-ring', 'right-pinky'];
  rightFingers.forEach(finger => {
    const score = FINGERPRINT_SCORES[fingerprints.rightHand[rightFingers.indexOf(finger)]] || 0;
    rightHandScore += score;
    totalScore += score;
  });

  return {
    total: totalScore,
    leftHand: leftHandScore,
    rightHand: rightHandScore,
    maxScore: 20
  };
}

// Анализ на типа образование
function calculateEducationType(formula, fingerprints) {
  const spiralPercentage = calculatePatternPercentage(fingerprints, 'Спирала', 'Двойна Спирала');
  const loopPercentage = calculatePatternPercentage(fingerprints, 'L-Примка', 'R-Примка');
  const archPercentage = calculatePatternPercentage(fingerprints, 'Дъга', 'Палатковидна Дъга');

  return {
    technical: Math.min(100, 75 + (spiralPercentage * 0.5) + (formula.total * 2)),
    humanitarian: Math.min(100, 45 - (spiralPercentage * 0.3) + Math.max(0, (10 - formula.total) * 2)),
    naturalScience: Math.min(100, 70 + (spiralPercentage * 0.4) + (formula.total * 1.5)),
    economics: Math.min(100, 50 + (loopPercentage * 0.3) - (spiralPercentage * 0.2))
  };
}

// Анализ на професионални направления
function calculateProfessionalDirections(fingerprints) {
  const spiralCount = countPatterns(fingerprints, 'Спирала', 'Двойна Спирала');
  const loopCount = countPatterns(fingerprints, 'L-Примка', 'R-Примка');
  const archCount = countPatterns(fingerprints, 'Дъга', 'Палатковидна Дъга');

  const totalFingers = 10;
  const spiralPercentage = (spiralCount / totalFingers) * 100;
  const loopPercentage = (loopCount / totalFingers) * 100;
  const archPercentage = (archCount / totalFingers) * 100;

  return {
    analytical: Math.min(100, 60 + (spiralPercentage * 0.8) + (loopCount * 3)),
    creative: Math.min(100, 40 + (loopPercentage * 0.6) + (archCount * 2)),
    organizational: Math.min(100, 55 + (spiralPercentage * 0.4) + (loopCount * 2)),
    physical: Math.min(100, 30 + (archPercentage * 0.8) - (spiralPercentage * 0.3))
  };
}

// Анализ на професионални сфери
function calculateProfessionalSpheres(fingerprints) {
  const spiralCount = countPatterns(fingerprints, 'Спирала', 'Двойна Спирала');
  const loopCount = countPatterns(fingerprints, 'L-Примка', 'R-Примка');

  return {
    itAndTech: Math.min(100, 60 + (spiralCount * 6) + (loopCount * 2)),
    scienceAndResearch: Math.min(100, 55 + (spiralCount * 5) + (loopCount * 3)),
    financeAndAnalysis: Math.min(100, 45 + (loopCount * 4) + (spiralCount * 2)),
    education: Math.min(100, 40 + (loopCount * 3) + Math.max(0, (5 - spiralCount) * 3))
  };
}

// Анализ на модела за самореализация
function calculateSelfRealizationModel(formula, fingerprints) {
  const spiralPercentage = calculatePatternPercentage(fingerprints, 'Спирала', 'Двойна Спирала');
  const loopPercentage = calculatePatternPercentage(fingerprints, 'L-Примка', 'R-Примка');

  return {
    systematicApproach: Math.min(100, 65 + (formula.total * 1.5) + (spiralPercentage * 0.3)),
    planningAndOrganization: Math.min(100, 70 + (formula.total * 1.2) + (loopPercentage * 0.4)),
    creativeThinking: Math.min(100, 50 + (spiralPercentage * 0.6) + (loopPercentage * 0.3)),
    communication: Math.min(100, 40 + (loopPercentage * 0.8) - (spiralPercentage * 0.2))
  };
}

// Анализ на здравословното състояние
function calculateHealthAnalysis(fingerprints, formula) {
  const spiralCount = countPatterns(fingerprints, 'Спирала', 'Двойна Спирала');
  const loopCount = countPatterns(fingerprints, 'L-Примка', 'R-Примка');
  const archCount = countPatterns(fingerprints, 'Дъга', 'Палатковидна Дъга');

  return {
    stressRisk: Math.min(100, 40 + (spiralCount * 8) + (formula.total * 1.5)),
    immuneSystem: Math.min(100, 60 + (loopCount * 4) - (spiralCount * 2)),
    nervousSystem: Math.min(100, 55 + (spiralCount * 6) + (loopCount * 2)),
    physicalEndurance: Math.min(100, 50 + (archCount * 5) + (loopCount * 2))
  };
}

// Анализ на спорт
function calculateSportsAnalysis(fingerprints) {
  const formula = calculateDermatoglyphicFormula(fingerprints);

  return {
    intellectualSports: Math.min(100, 60 + (formula.total * 2) + (countPatterns(fingerprints, 'Спирала', 'Двойна Спирала') * 4)),
    individualSports: Math.min(100, 55 + (formula.total * 1.5) + (countPatterns(fingerprints, 'L-Примка', 'R-Примка') * 3)),
    teamSports: Math.min(100, 35 + (countPatterns(fingerprints, 'Дъга', 'Палатковидна Дъга') * 4) - (formula.total * 0.5))
  };
}

// Анализ на нервната система
function calculateNervousSystem(fingerprints, formula) {
  const spiralCount = countPatterns(fingerprints, 'Спирала', 'Двойна Спирала');
  const loopCount = countPatterns(fingerprints, 'L-Примка', 'R-Примка');

  return {
    concentration: Math.min(100, 65 + (spiralCount * 6) + (formula.total * 1.2)),
    reactionSpeed: Math.min(100, 60 + (spiralCount * 5) + (loopCount * 2)),
    stressResistance: Math.min(100, 55 + (loopCount * 4) - (spiralCount * 2)),
    adaptability: Math.min(100, 70 + (loopCount * 3) + (spiralCount * 2))
  };
}

// Анализ на поведенческата адаптация
function calculateBehavioralAdaptation(fingerprints) {
  const formula = calculateDermatoglyphicFormula(fingerprints);
  const spiralPercentage = calculatePatternPercentage(fingerprints, 'Спирала', 'Двойна Спирала');

  return {
    systematicAdaptation: Math.min(100, 65 + (formula.total * 1.8) + (spiralPercentage * 0.4)),
    flexibleAdaptation: Math.min(100, 50 + (calculatePatternPercentage(fingerprints, 'L-Примка', 'R-Примка') * 0.7)),
    conservativeAdaptation: Math.min(100, 35 + Math.max(0, (8 - formula.total) * 2))
  };
}

// Анализ на темперамента
function calculateTemperament(fingerprints) {
  const spiralCount = countPatterns(fingerprints, 'Спирала', 'Двойна Спирала');
  const loopCount = countPatterns(fingerprints, 'L-Примка', 'R-Примка');
  const archCount = countPatterns(fingerprints, 'Дъга', 'Палатковидна Дъга');

  return {
    melancholic: Math.min(100, 25 + (archCount * 8) - (spiralCount * 3)),
    phlegmatic: Math.min(100, 60 + (loopCount * 4) + (spiralCount * 2)),
    sanguine: Math.min(100, 50 + (loopCount * 3) + (spiralCount * 3)),
    choleric: Math.min(100, 35 + (spiralCount * 5) + Math.max(0, (loopCount - 3) * 2))
  };
}

// Анализ на възприемането на новости
function calculateNewsPerception(fingerprints) {
  const spiralCount = countPatterns(fingerprints, 'Спирала', 'Двойна Спирала');
  const loopCount = countPatterns(fingerprints, 'L-Примка', 'R-Примка');
  const archCount = countPatterns(fingerprints, 'Дъга', 'Палатковидна Дъга');

  return {
    analyticalPerception: Math.min(100, 70 + (spiralCount * 6) + (loopCount * 2)),
    intuitivePerception: Math.min(100, 50 + (spiralCount * 4) + (archCount * 2)),
    practicalPerception: Math.min(100, 60 + (loopCount * 4) + (spiralCount * 3))
  };
}

// Помощни функции
function countPatterns(fingerprints, ...patterns) {
  let count = 0;

  Object.values(fingerprints.leftHand).forEach(pattern => {
    if (patterns.includes(pattern)) count++;
  });

  Object.values(fingerprints.rightHand).forEach(pattern => {
    if (patterns.includes(pattern)) count++;
  });

  return count;
}

function calculatePatternPercentage(fingerprints, ...patterns) {
  const count = countPatterns(fingerprints, ...patterns);
  return (count / 10) * 100; // 10 пръста общо
}

// Генериране на пълен анализ
function generateCompleteAnalysis(fingerprints) {
  const formula = calculateDermatoglyphicFormula(fingerprints);

  return {
    dermatoglyphicFormula: formula,
    educationType: calculateEducationType(formula, fingerprints),
    professionalDirections: calculateProfessionalDirections(fingerprints),
    professionalSpheres: calculateProfessionalSpheres(fingerprints),
    selfRealizationModel: calculateSelfRealizationModel(formula, fingerprints),
    healthAnalysis: calculateHealthAnalysis(fingerprints, formula),
    sportsAnalysis: calculateSportsAnalysis(fingerprints),
    nervousSystem: calculateNervousSystem(fingerprints, formula),
    behavioralAdaptation: calculateBehavioralAdaptation(fingerprints),
    temperament: calculateTemperament(fingerprints),
    newsPerception: calculateNewsPerception(fingerprints)
  };
}
