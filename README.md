# Doxtr reactor builder assets

This image provides assets, the doxtr/reactor needs to build a proper container for generating documentation as downloading these assets takes a long time and they don't change that often. The image is not designed to be used any other way.


# Build podman Image

In order for all of this to work, you need to have podman installed. You can [get it here](https://podman-desktop.io/).

You do not need to do this, but if you want to build the image yourself, you can do so with the following command.

``` bash
$#> podman build -t doxtr/reactor-builder-assets .
```

You can build and push your own version of the image easily with:

```
#> export VERSION=0.0.1 && podman build -t doxtr/reactor-builder-assets:$VERSION . && podman push doxtr/reactor-builder-assets:$VERSION
```

# Building for Github release

Tag what you want to release

``` bash
#> export VERSION=v1.0.0 && git tag $VERSION && git push origin $VERSION
```

Then hit 'Create a new release'on the right side of your github repository.

## Redoing the same version

Delete the tag, tag again, push release button

```
#> export VERSION=v1.0.0
#> git tag -d $VERSION && git push --delete origin $VERSION && git tag $VERSION && git push origin $VERSION
```

