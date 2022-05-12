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

    if (leftHandThumb != null)
    {
        // let className = leftHandThumb;

        // if (className.classList.contains("double_spiral")) {
        //     console.log(className.className)
        // }

        let allFingerprints = [
            {
                finger: "left-thumb",
                print: leftHandThumb.id
            },
            {
                finger: "left-index",
                print: leftHandIndex.id
            },
            {
                finger: "left-middle",
                print: leftHandMiddle.id
            },
            {
                finger: "left-ring",
                print: leftHandRing.id
            },
             {
                finger: "left-pinky",
                print: leftHandPinky.id
            }
        ]

        for (let i = 0; i < allFingerprints.length; i++){
            console.log(allFingerprints[i].finger + " / " + allFingerprints[i].print + "\n");
        }
        

        // for (let i = 1; i <= 10; i++)
        // {

            
        // }


        // switch (className = leftHandThumb.classList) {

        //     case className.contains("double_spiral"):
        //         console.log("Left Thumb is a Double Spiral!")
        //         break;
        //     default:
        //         console.log("Something Else I guess")

        // }
        // console.log("There is a submission" + id)
    } else {
        alert("There is no submitted fingerprint?");
        
    }
}
// && leftHandIndex && leftHandMiddle && leftHandRing && leftHandPinky &&
        // rightHandThumb && rightHandIndex && rightHandMiddle && rightHandRing && rightHandPinky