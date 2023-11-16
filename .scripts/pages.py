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
    for feature_model_path in {
            path
            for path in SOURCE.iterdir() if path.is_dir()
            and path.name not in EXCLUDE and not path.name.startswith('.')
    }:
        try:
            if feature_model_path.is_dir():
                local.cwd.chdir(feature_model_path)

                model_path = feature_model_path / 'FeatureModel.xml'
                if not Path(model_path).exists():
                    logging.warning("Could not find feature model "
                                    f"for {feature_model_path}")

                try:
                    fm = vf.feature_model.loadFeatureModel(str(model_path))
                except RuntimeError:
                    logging.error(feature_model_path.name)
                    continue

                file_path = Path(FILES, feature_model_path.name + '.xml')
                shutil.copy(model_path, file_path)

                viewer = local[str(VIEWER)]['-viewer', 'cat', model_path]

                image_path = Path(IMAGES, feature_model_path.name + '.png')
                png = local["dot"]['-Tpng', '-o', image_path]
                (viewer | png)()

                vector_path = Path(IMAGES, feature_model_path.name + '.svg')
                svg = local["dot"]['-Tsvg', '-o', vector_path]
                (viewer | svg)()

                thumbnail_path = Path(IMAGES,
                                      feature_model_path.name + '-scaled.webp')
                image = Image.open(image_path)
                image.thumbnail((512, 512), resample=Image.BICUBIC)
                with open(thumbnail_path, 'wb+') as file:
                    image.save(file.name, format='WebP')

                index[feature_model_path.name] = {
                    'name':
                    feature_model_path.name,
                    'metadata': {
                        'features':
                        fm.size(),
                        'depth':
                        0,
                        'booleanConstraints':
                        len(list(fm.booleanConstraints)),
                        'nonBooleanConstraints':
                        len(list(fm.nonBooleanConstraints)),
                        'mixedConstraints':
                        len(list(fm.mixedConstraints))
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
            logging.error(feature_model_path.name)
            continue

    with open(INDEX, mode='w', encoding='UTF-8') as file:
        file.write(json.dumps(index, indent=1, sort_keys=True))


if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG, handlers=[])
    main()
