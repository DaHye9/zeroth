import sys
import re
from pykospacing import Spacing


#reload(sys)
#sys.setdefaultencoding("UTF-8")
sent = sys.argv[1]
spacing = Spacing()
spaced_sent = re.sub('(.*)', '\\1.', sent)
spaced_sent = spacing(spaced_sent)
print (spaced_sent)
