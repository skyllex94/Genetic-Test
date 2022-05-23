
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
    var name = document.getElementById('name').value;
    if (name == "") {
        console.log("Your name is blank")
        document.querySelector('.status').innerHTML = "Името не може да бъде празно";
        return false;
    }
    var email = document.getElementById('email').value;
    if (email == "") {
        document.querySelector('.status').innerHTML = "Имейла не може да бъде празно";
        return false;
    } else {
        var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        if (!re.test(email)) {
            document.querySelector('.status').innerHTML = "Имейла не е валиден";
            return false;
        }
    }
    var subject = document.getElementById('subject').value;
    if (subject == "") {
        document.querySelector('.status').innerHTML = "Заглавието не може да бъде празно";
        return false;
    }
    var message = document.getElementById('message').value;
    if (message == "") {
        document.querySelector('.status').innerHTML = "Cъобщението не може да бъде празно";
        return false;
    }
    document.querySelector('.status').innerHTML = "Изпращане...";
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
        empty.addEventListener('dragover', function dragOver(e){
            e.preventDefault();
            empty.classList.add("hovered");
            
        });
        empty.addEventListener('dragenter', dragEnter);
        empty.addEventListener('dragleave', dragLeave);
        empty.addEventListener('drop', dragDrop);
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
    if (target == null){
        // If not, create a copy of the sourse item being dragged
        let clone = src.cloneNode(true);
        clone.id = document.getElementById(data).id + "1";
        // Add a class of choice so it can be error checked later
        clone.classList.add("choice");
        ev.target.appendChild(clone);
    } else {
        let parent = src.parentNode;
        // check if the drag is asked from a finger rather than the symbol type
        if (parent.classList.contains("placeholder") || 
        (parent.classList.contains("symbol") && target.parentNode.classList.contains("symbol"))) {
            return 1;
        } else {
            // Replace the placeholder with the new symbol being dragged
            let clone = src.cloneNode(true);
            ev.currentTarget.replaceChild(clone, target);
        }
    }
}

//  ---- Confirm selection with fingerprint data collected from the online form  ----
function confirmData()
{
    // All fingers selection
    let leftHandThumb = document.getElementById("left-thumb").firstElementChild;
    let leftHandIndex = document.getElementById("left-index").firstElementChild;
    let leftHandMiddle = document.getElementById("left-middle").firstElementChild;
    let leftHandRing = document.getElementById("left-ring").firstElementChild;
    let leftHandPinky = document.getElementById("left-pinky").firstElementChild;

    let rightHandThumb = document.getElementById("right-thumb").firstElementChild;
    let rightHandIndex = document.getElementById("right-index").firstElementChild;
    let rightHandMiddle = document.getElementById("right-middle").firstElementChild;
    let rightHandRing = document.getElementById("right-ring").firstElementChild;
    let rightHandPinky = document.getElementById("right-pinky").firstElementChild;

    // All symbols selection
    let spiral =  document.getElementById("drag_spiral");
    let doubleSpiral = document.getElementById("drag_double_spiral");
    let rainbow = document.getElementById("drag_rainbow");
    let rKnot = document.getElementById("drag_r_knot");
    let lKnot = document.getElementById("drag_l_knot");
    let tent = document.getElementById("drag_tent");

    // Arrays of all the symbols and fingers
    let arrFingers = [leftHandThumb, leftHandIndex, leftHandMiddle, leftHandRing, leftHandPinky, 
    rightHandThumb, rightHandIndex, rightHandMiddle, rightHandRing, rightHandPinky];
    let arrSymbols = [spiral, doubleSpiral, rainbow, rKnot, lKnot, tent];

    let age = document.getElementById("age").value;
        if (age > 99) {
            alert("Моля прегледайте годините си.");
            return 1;
        }

    let select = document.getElementById("gender");
    let gender = select.options[select.selectedIndex].text;
    console.log(gender);

    if (leftHandThumb && leftHandIndex && leftHandMiddle && leftHandRing && leftHandPinky && 
        rightHandThumb && rightHandIndex && rightHandMiddle && rightHandRing && rightHandPinky != null) {
        
        
        // Creating an objects with key-value pairs of all the fingers with their chosen symbol
        // When a symbol is dropped, it adds a "choice" class to be further fetched for the email body
        allChoicesEmailMessage =  {} // {"Ляв Палец" : "Двойна Спирала", "Ляв Показалец" : ...}
        let choices = document.querySelectorAll(".choice");
        let fingers = document.querySelectorAll(".finger");

        // Looping through each one and assigning them values
        for (let i = 0; i < choices.length; i++)
        {
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
        // emailBody += "Имейл на клиента: " + customerEmail.value + "\n" + "\n";
        // emailBody += " --- Пръстови отпечатъци ---" + "\n" + "\n";

        // Loop through each key-value and format it as you include it to the email body
        for (let i = 0; i < arrKeys.length; i++)
        {
            emailBody += (arrKeys[i] + " : " + arrValues[i] + "\n");
        }

        // Populate the hidden textarea with the selection
        let message = document.getElementById("message");
        message.value = emailBody;
        document.getElementById("sendData").disabled = false;
        document.getElementById("confirmSelection").disabled = true;

        // Disable dragging
        arrSymbols.forEach(symbol => symbol.setAttribute("draggable", false));
        arrFingers.forEach(finger => {
            finger.setAttribute("draggable", false);
            finger.parentElement.parentElement.parentElement.classList.replace("border-dark", "confirmed");
        });
    }
    else {
        alert("Моля въведете нужната информация във всички полета.");
    }
}

// ---- Response back from Elastic Email promise which will give a conditional alert message ----
function emailResponse(message)
{
    if (message == "OK") {
        return alert("Вашите резултати бяха изпратени към нас. Ще ви върнем отговор в следващите няколко дни. Благодарим Ви!");
    }
    else {
        return alert("Грешка с изпращането, моля проверете дали всички папили са въведели, ако грешката продължава свържете се с нас чрез контактната форма.");
    }
}

// fetch('https://jsonplaceholder.typicode.com/todos/1')
//   .then(resp => resp.blob())
//   .then(blob => {
//     const url = window.URL.createObjectURL(blob);
//     const a = document.createElement('a');
//     a.style.display = 'none';
//     a.href = url;
//     // the filename you want
//     a.download = 'blank-test.docx';
//     document.body.appendChild(a);
//     a.click();
//     window.URL.revokeObjectURL(url);
//     alert('your file has downloaded!'); // or you know, something with better UX...
//   })
//   .catch(() => alert('oh no!'));

// let uri = "https://genetictest-sv.com/wp-content/uploads/2020/06/instruction.bg_.docx";

// function downloadURI(uri, name) 
// {
//     var link = document.createElement("a");
//     // If you don't know the name or want to use
//     // the webserver default set name = ''
//     link.setAttribute('download', name);
//     link.href = uri;
//     document.body.appendChild(link);
//     link.click();
//     link.remove();
// }

function fileDownload()
{
    document.getElementById('download').click();
}