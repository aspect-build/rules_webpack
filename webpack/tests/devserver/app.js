import {print} from "./helper";

print();

if (module.hot) {
    module.hot.accept('./helper.js', print);
}