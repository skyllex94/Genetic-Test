// let currentYear = new Date().getFullYear();
// document.getElementById("getYear").innerHTML = currentYear;

console.log("Here!")

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
    ev.dataTransfer.setData("item", ev.target.id);
}

function drop(ev) {
    ev.preventDefault();
    let data = ev.dataTransfer.getData("item");
    let src = document.getElementById(data);
    let target = ev.currentTarget.firstElementChild;

    if (target == null){
        let clone = src.cloneNode(true);
        clone.id = document.getElementById(data).id + "1";
        clone.classList.add("choice");
        ev.target.appendChild(clone);
    } else {
        let parent = src.parentNode;
        // check if the drag is asked from a finger 
        // rather than the types of fingerprints selection
        if (parent.classList.contains("placeholder")) {
            return 1;
        } else {
            let clone = src.cloneNode(true);
            ev.currentTarget.replaceChild(clone, target);
        }
    }
}

// Send Email From Contact Form - ElasticEmail SMTP provider
function sendEmail() 
{
    Email.send({
        Host: "smtp.elasticemail.com",
        Username: "skyllex@abv.bg",
        Password: "3B3620376E05424FE3929662BA017F291276",
        To: "kkanchev94@gmail.com",
        From: document.getElementById("email").value,
        Subject: document.getElementById("subject").value,
        Body: document.getElementById("message").value
    }).then(
        message => alert(message)
    );
}

// Send the fingerprint data collected from the online form

function sendData()
{
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

    let customerName = document.getElementById("name");
    let customerEmail = document.getElementById("email");

    if (leftHandThumb && leftHandIndex && leftHandMiddle && leftHandRing && leftHandPinky && 
        rightHandThumb && rightHandIndex && rightHandMiddle && rightHandRing && rightHandPinky &&
        customerName.value && customerEmail.value != null)
    {

        //  Creating an objects with key-value pairs of all the fingers with their chosen symbol
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
        let emailBody = "Име на клиента: " + customerName.value + "<br>";
        emailBody += "Имейл на клиента: " + customerEmail.value + "<br>";
        emailBody += " --- Пръстови отпечатъци ---" + "<br>" + "<br>";

        // Loop through each key-value and format it as you include it to the email body
        for (let i = 0; i < arrKeys.length; i++)
        {
            emailBody += (arrKeys[i] + " : " + arrValues[i] + "<br>");
        }
        
        // Send Email with ElasticEmail SMTP service
        Email.send({
                Host: "smtp.elasticemail.com",
                // Current encrypted credentials
                Username: "skyllex@abv.bg",
                Password: "3B3620376E05424FE3929662BA017F291276",
                To: "kkanchev94@gmail.com",
                From: customerEmail.value, // "skyllex@abv.bg",
                Subject: "New Inquery",
                Body: emailBody
            }).then(
                // message => alert(message)
                message => emailResponse(message)
            );

    } else {
        alert("Моля въведете нужната информация във всички полета.");
    }
}

function emailResponse(message)
{
    if (message == "OK") {
        return alert("Вашите резултати бяха изпратени към нас. Ще ви върнем отговор в следващите няколко дни. Благодарим Ви!");
    }
    else {
        return alert("Грешка с изпращането, моля проверете дали всички папили са въведели, ако грешката продължава свържете се с нас в контакната форма.");
    }
}