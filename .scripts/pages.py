#!/usr/bin/python3

import vara_feature as vf

import json
import logging
import shutil
import typing as tp
from pathlib import Path

from PIL import Image, ImageFile
from plumbum import ProcessExecutionError, local

CWD = local.cwd

EXTERNAL = Path('.external').absolute()
VIEWER = EXTERNAL / 'vara-feature/build/bin/fm-viewer'

ROOT = Path('.github/pages').absolute()

FILES = ROOT / 'files'
FILES.mkdir(exist_ok=True)

IMAGES = ROOT / 'images'
IMAGES.mkdir(exist_ok=True)

INDEX = ROOT / 'index.json'

SOURCE = CWD
EXCLUDE = ['x264', 'Polly']


def sanitize(root: Path, path: Path) -> str:
    return str(path.relative_to(root))


def main() -> None:
    index: tp.Dict[str, tp.Dict[str, tp.Any]] = {}
    for feature_model in {
            path for path in SOURCE.iterdir() if path.is_dir() and
            path.name not in EXCLUDE and not path.name.startswith('.')
    }:
        try:
            if feature_model.is_dir():
                local.cwd.chdir(feature_model)

                model_path = feature_model / 'FeatureModel.xml'
                try:
                    fm = vf.feature_model.loadFeatureModel(str(model_path))
                except RuntimeError:
                    logging.error(feature_model.name)
                    continue

                file_path = Path(FILES, feature_model.name + '.xml')
                shutil.copy(model_path, file_path)

                viewer = local[str(VIEWER)]['-viewer', 'cat', model_path]

                image_path = Path(IMAGES, feature_model.name + '.png')
                png = local["dot"]['-Tpng', '-o', image_path]
                (viewer | png)()

                vector_path = Path(IMAGES, feature_model.name + '.svg')
                svg = local["dot"]['-Tsvg', '-o', vector_path]
                (viewer | svg)()

                thumbnail_path = Path(IMAGES,
                                      feature_model.name + '-scaled.webp')
                image = Image.open(image_path)
                image.thumbnail((512, 512), resample=Image.BICUBIC)
                with open(thumbnail_path, 'wb+') as file:
                    image.save(file.name, format='WebP')

                index[feature_model.name] = {
                    'name': feature_model.name,
                    'metadata': {
                        'features': fm.size(),
                        'constraints': 0,
                        'depth': 0
                    },
                    'files': [{
                        'format': 'xml',
                        'source': sanitize(ROOT, file_path)
                    }, {
                        'format': 'svg',
                        'source': sanitize(ROOT, vector_path)
                    }, {
                        'format': 'png',
                        'source': sanitize(ROOT, image_path)
                    }],
                    'preview': {
                        'source': sanitize(ROOT, image_path),
                        'thumbnail': sanitize(ROOT, thumbnail_path)
                    }
                }
        except ProcessExecutionError:
            logging.error(feature_model.name)
            continue

    with open(INDEX, mode='w', encoding='UTF-8') as file:
        file.write(json.dumps(index, indent=1, sort_keys=True))


if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG, handlers=[])
    main()
