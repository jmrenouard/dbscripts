import glob
import sys

from pypdf import PdfWriter

def merge_pdfs(_pdfs, _out):
    merger = PdfWriter()

    for pdf in _pdfs:
        merger.append(pdf)

    merger.write(_out)
    merger.close()


if __name__ == '__main__':
    pdfs = sys.argv[1:]
    out=pdfs.pop()

    print("File to merge : " +str(pdfs))
    print("Result File   : " +out)
    merge_pdfs(pdfs, out)
