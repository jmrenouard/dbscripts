#!python3
import markdown
import sys

config = {
    'extra': {
        'footnotes': {
            'UNIQUE_IDS': True
        },
        'fenced_code': {
            'lang_prefix': 'lang-'
        }
    },
    'toc': {
        'permalink': True
    }
}

htmlHeader = """
<!DOCTYPE html>
<html>
<head>
		<meta charset="utf-8">
		<title>HTML Page</title>
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/3.0.1/github-markdown.min.css">
		<style>
		body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    margin: 20px;
    //background-color: #f4f4f4;
    color: #333;
    padding: 20px;
}

h1, h2, h3, h4, h5, h6 {
    margin-top: 20px;
    padding-bottom: 8px;
    margin-bottom: 8px;
    border-bottom: solid 1px #e1e1e1;
}
h1 {
	background-color: #f4f4f4;
	border-left: 10px solid #3498db;
	margin: 20px 10px;
  padding: 10px 20px;
	}
body {
    counter-reset: chapter 1 section 0;
}

h2 {
    counter-reset: slide 0;
    counter-increment: section;
}
h3 {
    counter-increment: slide;
}

h2:before {
    content:  counter(section) " - ";
}
h3:before {
    content: counter(section) "." counter(slide) " - ";
}
a {
    color: #3498db;
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

p {
    margin: 10px 0;
}

blockquote {
    //background-color: #fff;
		background-color: #f4f4f4;
    border-left: 10px solid #3498db;
    margin: 20px 10px;
    padding: 10px 20px;
    font-style: italic;
}

code {
    background-color: #f8f8f8;
    border: 1px solid #ddd;
    padding: 2px 4px;
    font-family: 'Courier New', monospace;
}

pre {
    background-color: #f8f8f8;
    border: 1px solid #ddd;
    padding: 10px;
    overflow-x: auto;
}

pre code {
    border: none;
    background-color: transparent;
}

ul, ol {
    padding-left: 20px;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin: 20px 0;
}

table, th, td {
    border: 1px solid #ddd;
}

table th, table td {
    padding: 10px;
    text-align: left;
}

img {
    max-width: 100%;
    display: block;
    margin: 20px 0;
}

</style>
</head>
<body>

"""

htmlFooter = """
<script>
document.addEventListener("DOMContentLoaded", function() {
		// Select the first h1 element
    var firstH1 = document.querySelector('h1');

    if (firstH1) {
        document.title = firstH1.innerHTML

				// Create a new div element
        var newDiv = document.createElement('div');
        newDiv.id = 'table-of-contents';
				newDiv.innerHTML = '<h2>Table of Contents</h2>';
        firstH1.parentNode.insertBefore(newDiv, firstH1.nextSibling);
    }
		document.getElementById('table-of-contents');
    var toc = document.getElementById('table-of-contents');
    var headings = document.querySelectorAll('h2, h3, h4, h5, h6');

    var tocList = document.createElement('ol');

    headings.forEach(function(heading, index) {
        var anchor = "toc-" + index;
        var listItem = document.createElement('li');
        var link = document.createElement('a');
        heading.id = anchor;
        link.href = "#" + anchor;
        link.innerText = heading.innerText;

        listItem.appendChild(link);

        if (heading.tagName === 'H2') {
            var subList = document.createElement('ul');
            listItem.appendChild(subList);
            tocList.appendChild(listItem);
        } else if (heading.tagName === 'H3') {
            var lastListItem = tocList.lastChild;
            if (lastListItem) {
                var subList = lastListItem.querySelector('ul');
                if (subList) {
                    subList.appendChild(listItem);
                }
            }
        } else {
            tocList.appendChild(listItem);
        }
    });

    toc.appendChild(tocList);
});
</script>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/styles/default.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/highlight.min.js"></script>

<!-- and it's easy to individually load additional languages -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/languages/go.min.js"></script>

<script>hljs.highlightAll();</script>
<script src="https://superal.github.io/canvas2image/canvas2image.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/0.4.1/html2canvas.min.js"></script>
</body>
"""

def markdown_to_html_and_linkedin_post(md_file_path, html_file_path):
    # Read the markdown file
    with open(md_file_path, 'r') as file:
        content = file.read()

    # Convert markdown to HTML
    html_content = markdown.markdown(content, extensions=['extra'], extension_configs=config)

    # Save the HTML content to the specified HTML file
    with open(html_file_path, 'w') as html_file:
        html_file.write(htmlHeader)
        html_file.write(html_content)
        html_file.write(htmlFooter)
        
    # Convert HTML to plain text for LinkedIn
    plain_text = ''.join(html_content.split('<p>')).replace('</p>', '\n\n').replace('<br />', '\n')


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script_name.py <path_to_markdown_file> <path_to_save_html_content>")
        sys.exit(1)

    md_file_path = sys.argv[1]
    html_file_path = sys.argv[2]
    print("Converted MD Content")
    markdown_to_html_and_linkedin_post(md_file_path, html_file_path)
