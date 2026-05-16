import Foundation

var index: Int32 = 0
OSAtomicAdd32Barrier(1, &index)
print(index)
