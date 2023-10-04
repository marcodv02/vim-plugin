from pylatexenc.latexwalker import LatexWalker, LatexEnvironmentNode
from time import sleep
keys= [
    'axiom',
    'math_def',
    'oss',
    'affermazione',
    'theo'
]
class Parser:
    mov= 0
    nodo_id= 0
    offset= 0
    nodi= ['\\begin{document}']
    nodi_names= ['main']
    def __init__(self, content, offset= 0):
        self.content= content
        self.offset= offset
        start= self.content.find('\\begin{document}')
        end= self.content.find('\end{document}')
        self.rec_fun(start+len('\\begin{document}'), end)
        self.nodi[0]= self.content[:start]+self.nodi[0]+self.content[end:]
    def rec_fun(self, start= 0, end=-1, j=0):
        if end==-1:
            end= len(self.content)

        divide= self.divider(start, end)


        if len(divide)==0:
            self.nodi[j]+= self.content[start:end]
            return
        i= 1

        self.nodi[j]+= self.content[start:divide[0]]
        start= divide[0]
        while i<len(divide):
            start= divide[i-1]
            
            sleep(0.2)
            if i%2:
                nome, start_bO= self.get_beg_name(start)

                if nome in keys:
                    self.nodi.append('')
                    self.nodi[j]+= '\\nodeServer{'+str(self.offset+len(self.nodi)-1)+'}'
                    self.nodi_names.append(nome)
                    self.rec_fun(start_bO, divide[i], len(self.nodi)-1)
                else:
                    self.nodi[j]+= '\\begin{'+nome+'}'
                    self.rec_fun(start_bO, divide[i], j)
                    self.nodi[j]+= '\end{'+nome+'}'
            else:
                start_bO= start
                if (self.content[start:start+4]=='\end'):
                    nome, start_bO= self.get_end_name(start)
                self.nodi[j]+= self.content[start_bO:divide[i]]
            i+= 1
        start= divide[i-1]
        start_bO= start

        if (self.content[start:start+4]=='\end'):
            nome, start_bO= self.get_end_name(start)

        
        self.nodi[j]+= self.content[start_bO:end]

    def divider(self, start_O, end):#da migliorare
        stack= []
        count= 0

        while True:
            kind, start= self.nearest(start_O, end)
            
            if start==-1:
                return stack

            if kind=='begin':
                if count==0:
                    stack.append(start)

                count+= 1
                name, start_O= self.get_beg_name(start)                
            else: 
                if count==1:
                    stack.append(start)

                count-= 1
                name, start_O= self.get_end_name(start)

    def nearest(self, start, end):
        index_b= self.content.find('\\begin{', start, end)
        index_e= self.content.find('\\end{', start, end)
        
        if index_e==-1:
            return 'end', -1# end
        #if index_b==-1:
        #    return 'begin', -1
        
        if index_b<index_e and index_b!=-1:
            #name, index_b= self.get_beg_name(index_b) 
            return 'begin', index_b
        else:
            #name, index_e= self.get_end_name(index_e)
            return 'end', index_e
    def get_end_name(self, index_e):
        name= ''
        index_e+= len('\end')
        if (len(self.content)<=index_e):
            return name, len(self.content)
        while (self.content[index_e]==' '):
            index_e+= 1
        if (self.content[index_e]!='{'):
            pass
            #print("Errore", self.content[index_e:index_e+4])
        index_e+= 1
        while (index_e<len(self.content) and self.content[index_e]!='}'):
            name+= self.content[index_e]
            index_e+= 1
        index_e+= 1
        return name, index_e
    def get_beg_name(self, index_b):
        name= ''
        index_b+= len('\\begin')
        if (len(self.content)<=index_b):
            return name, len(self.content)
        while (self.content[index_b]==' '):
            index_b+= 1
        if (self.content[index_b]!='{'):
            pass#print("Errore", self.content[index_b])
        index_b+= 1
        while (index_b<len(self.content) and self.content[index_b]!='}'):
            name+= self.content[index_b]
            index_b+= 1
        index_b+= 1
        return name, index_b
