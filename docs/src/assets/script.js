
async function getText(url) {
    let f = await fetch(url);
    let text = await f.text();
    return text
}

async function process() {
    # Drop extension regex; thanks to https://stackoverflow.com/questions/25351184.
    const rx = /\.[^/.]+$/;
    output_dir = window.location.href.replace(rx, "")
    const url = output_dir + '/c/1/1.html';
    console.log('url: ' + url);
    var output = await getText(url);
    console.log('output: ' + output);
    const el = document.getElementById('d');
    console.log(el);
}

process()
