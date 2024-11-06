This recipe is used to quickly check the definition of English words. Here is a version that translates English words into Chinese. You can also use other language translations by replacing the dictionary files and command parameters used.

![preview](preview.tiff)

## Steps for usage

#### 1. Install [sdcv](https://github.com/Dushistov/sdcv)

This recipe relies on the command line tool of sdcv, an offline dictionary query service.

 **MacOS**
```
brew install sdcv
```

**Linux**
```
sudo apt-get install sdcv
```

For other platforms, please refer to [sdcv](https://github.com/Dushistov/sdcv)
#### 2. Configure dictionary

move the dictionary data to ~/.stardict/dic

for example, to use **stardict-quick_eng-zh_CN-2.4.2**, you can run the following command (create folder first if required)

```
cp -r /stardict/stardict-quick_eng-zh_CN-2.4.2 ~/.stardict/dic
```