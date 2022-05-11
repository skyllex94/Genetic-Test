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
    // let yes = ev.dataTransfer.getData("item")
    // yes.appendChild(document.getElementById(p));
    // let pr = p.cloneNode(true);
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
        console.log(parent.className);
        if (parent.classList.contains("placeholder")) {
            return 1;
        } else {
            let clone = src.cloneNode(true);
            ev.currentTarget.replaceChild(clone, target);
        }
        
    }
    
    
    // copyItem.id = document.getElementById(data).id + "1";
    // ev.target.appendChild(copyItem);

}