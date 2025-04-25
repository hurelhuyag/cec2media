window.close = function () {
  console.log("window close requested");
  fetch("http://localhost:8080/close");
}