
async function getText(url) {
    let f = await fetch(url);
    let text = await f.text();
    return text
}

async function process() {
    output_dir = window.location.href.replace(/\.[^/.]+$/, "")
    const url = output_dir + '/c/1/1.html';
    console.log('url: ' + url);
    var output = await getText(url);
    console.log('output: ' + output);
    const el = document.getElementById('d');
    console.log(el);
}

process()
