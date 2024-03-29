const ready = (fn) => {
  if (document.readyState != 'loading'){
    fn();
  } else {
    document.addEventListener('DOMContentLoaded', fn);
  }
}


const ajaxRequest = (data, path, loop = 0, type = 'application/x-www-form-urlencoded; charset=UTF-8') => {
	const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  const request = new XMLHttpRequest()

  request.open('POST', path, true)
  request.setRequestHeader('X-CSRF-Token', csrfToken)
  request.onerror = function() {
    console.log('there was an error with the request')
  };
  request.setRequestHeader('Content-Type', type)
  request.onload = function () {
    if (this.status === 500 && loop < 4) {
      setTimeout(() => ajaxRequest(data, path, loop + 1), 600)
    }
  };
  request.send(data)
  return request
}


const makeUniqueId = (length) => {
  let result           = '';
  const characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const charactersLength = characters.length;
  for ( let i = 0; i < length; i++ ) {
     result += characters.charAt(Math.floor(Math.random() * charactersLength));
  }
  return result
}

const showAlert = (message, hideTime = 8000) => {
	let alertGroup
	if (document.querySelector('.alert_group')) {
		alertGroup = document.querySelector('.alert_group')
	} else {
		const innerWrap = document.querySelector('#inner-wrap')
		alertGroup = document.createElement('div')
		alertGroup.classList.add('alert_group')
		innerWrap.prepend(alertGroup)
  }
  const otherAlerts = document.querySelectorAll('.alert_wrapper')

	const alertWrapper = document.createElement('div')
	alertWrapper.classList.add('alert_wrapper', 'alert_hide')
	alertGroup.appendChild(alertWrapper)
	const alertNotice = document.createElement('div')
	alertNotice.classList.add('alert', 'alert-notice')
	alertNotice.innerHTML = message
	alertWrapper.appendChild(alertNotice)
	setTimeout(() => {
		alertWrapper.classList.remove('alert_hide')
  }, 15)

  if (otherAlerts.length > 0) {
    setTimeout(() => {
      otherAlerts.forEach(el => {
        el.classList.add('alert_hide')
      })
    }, 600)
  }


	setTimeout(() => {
		alertWrapper.classList.add('alert_hide')
	}, hideTime)

}


const qs = s => document.createDocumentFragment().querySelector(s)

const isSelectorValid = selector => {
  try { qs(selector) }
  catch (e) { return false }
  return true
}

const isMobileDevice = () => {
  return (typeof window.orientation !== "undefined") || (navigator.userAgent.indexOf('IEMobile') !== -1);
};

const toKebabCase = str => (
  str && str.match(/[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+/g)
    .map(x => x.toLowerCase())
    .join('-')
)

const toCamelCase = str => (
  str && str.toLowerCase()
    .replace(/[^a-zA-Z0-9]+(.)/g, (m, chr) => chr.toUpperCase())
)

function switchShoppingListClass(openBool = null) {
  if (!!openBool) {
    document.querySelector('#inner-wrap').style.width = "calc(100% - 30rem)"
  } else if (!openBool) {
    document.querySelector('#inner-wrap').style.width = "100%"
  }
}

let recipeListUpdateNeeded = false

let timeoutId;

function addRecipeToPlanner(
	encodedId,
	csrfToken,
	updatePlannerRecipes,
	updateSuggestedRecipes,
	updateCheckedPortionCount,
	updateTotalPortionCount,
  updateShoppingListPortions,
  date = null,
  updateShoppingListLoading
) {
  console.log('addRecipeToPlanner', date)

	const data = {
		method: 'post',
    body: JSON.stringify({
      "recipe_id": encodedId,
      "date": date
    }),
		headers: {
			'Content-Type': 'application/json',
			'X-CSRF-Token': csrfToken
		},
		credentials: 'same-origin'
  }

  showAlert("Adding recipe to your planner")

  const addRecipe = () => {
    fetch("/planner/recipe_add", data).then((response) => {
      if(response.status === 200){
        return response.json();
      } else {
        console.warn('Something went wrong! Maybe refresh the page and try again')
        if (response.status === 408) {
          // server busy, update needed
          console.log("server busy, update needed")
          recipeListUpdateNeeded = true
          if (window !== undefined) {
            timeoutId = window.setTimeout(() => {
              addRecipe()
            }, 2000)
          }
        }
      }
    }).then((jsonResponse) => {
      updatePlannerRecipes(jsonResponse.plannerRecipes)
      updateSuggestedRecipes(jsonResponse.suggestedRecipes)
      updateCheckedPortionCount(jsonResponse.checkedPortionCount)
      updateTotalPortionCount(jsonResponse.totalPortionCount)
      updateShoppingListPortions(jsonResponse.shoppingListPortions)
      updateShoppingListLoading(false)

      recipeListUpdateNeeded = false
      if (window !== undefined) {
        window.clearTimeout(timeoutId)
      }

      showAlert("Recipe added to your planner")
    });
  }

  if(recipeListUpdateNeeded === false) {
    addRecipe()
  }


}

export {
  ready,
  ajaxRequest,
  makeUniqueId,
  showAlert,
  isSelectorValid,
  isMobileDevice,
  toKebabCase,
  toCamelCase,
  switchShoppingListClass,
  addRecipeToPlanner
}
