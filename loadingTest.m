% testing for all testfiles

[timeData,info,Header] = importHDF('./testFiles/test_inca.hdf');

assert(all(size(timeData.ControlSignal_Decoded) == [24 6627]) ,'multi type import subdivides timeData', 1);
assert(all(size(timeData.Audio_Decoded) == [5 212064]) ,'multi type import subdivides timeData', 1);
assert(all(size(timeData.Codec_CAN_24_HEADlab_1) == [1 212064]) ,'multi type import subdivides timeData', 1);

[timeData,info,Header] = importHDF('./testFiles/test_singleChannel.hdf');
assert(all(size(timeData) == [1 153600]),'Single channel data imports timeData as vector');

[timeData,info,Header] = importHDF('./testFiles/test_multiChannel.hdf');
assert(all(size(timeData) == [4 480e3]),'Single channel data imports timeData as vector');
