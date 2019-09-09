import { ready, ajaxRequest, showAlert } from './utils'
import Sortable from 'sortablejs'
import {tns} from 'tiny-slider/src/tiny-slider'
import SVG from '../icons/symbol-defs.svg'
import PNGBin from '../icons/png-icons/bin.png'

const plannerRecipeAddData = (id, date) => (
	"recipe_id=" + id + "&planner_date=" + date
)

const plannerRecipeUpdateData = (e) => (
	"recipe_id=" + e.item.id + "&old_date=" + e.item.dataset.parentId + "&new_date=" + e.item.parentNode.id
)


const showWhiskList = () => {
	whisk.queue.push(function() {
		whisk.shoppingList.viewList({
			styles: {
				type: 'modal',
			},
		});
	});
}

const addToWhiskList = (whiskListPortions) => {
	whisk.queue.push(function() {
		whisk.shoppingList.addProductsToList({
			products: whiskListPortions
		})
	});
	ajaxRequest('Add Shopping list', '/stocks/add_shopping_list')
	setTimeout(() => checkForUpdates(function(shoppingListPortions) {
		renderShoppingList(shoppingListPortions)
		showAlert(`Shopping List items added to your <a href="/cupboards">cupboards</a>`)
	}), 2000)
}

const setupAddToWhiskShoppingListButton = (whiskListPortions) => {
	if (document.querySelector('#whisk-add-products')) {
		document.querySelector('#whisk-add-products').addEventListener('click', () => addToWhiskList(whiskListPortions))
	}
	if (document.querySelector('#view-whisk-list')) {
		document.querySelector('#view-whisk-list').removeEventListener('click', showWhiskList)
	}
}

const setupViewWhiskShoppingListButton = () => {
	if (document.querySelector('#view-whisk-list')) {
		document.querySelector('#view-whisk-list').addEventListener('click', showWhiskList)
	}
	if (document.querySelector('#whisk-add-products')) {
		document.querySelector('#whisk-add-products').removeEventListener('click', addToWhiskList)
	}
}


function checkForUpdates(onSuccess) {
  setTimeout(() => fetch("/planner/shopping_list").then((response) => {
    if(response.status != 200){
      setTimeout(() => checkForUpdates(onSuccess), 200)
    } else {
      response.json().then(onSuccess)
    }
  }), 400)
}

const renderShoppingList = (shoppingListPortions) => {

	const ShoppingList = document.querySelector('#planner_shopping_list')

	const ListTopUl = document.createElement('ul')
	ListTopUl.classList.add('planner_sl-recipe_list')

	const OldShoppingListContent = document.querySelector('#planner_shopping_list > ul')
	const shopOnlineBlock = document.querySelector('.shop_online_block')

	if (shoppingListPortions.length === 0 ){
		shopOnlineBlock.innerHTML = `<button id="view-whisk-list" class="list_block--collection--action">Open online shopping list</button>`
		hideShoppingList()
		ListTopUl.innerHTML = '<p>Shopping List is currently empty, move some recipes to your planner to get items added to this list</p>'
		setupViewWhiskShoppingListButton()
	} else {
		const whiskShoppingListPortions = []
		shoppingListPortions.forEach(function(portion) {
			const RecipePortionLi = document.createElement('li')
			RecipePortionLi.setAttribute('id', portion["shopping_list_portion_id"])
			RecipePortionLi.classList.add('shopping_list_portion')
			if (portion["portion_type"] == "combi") {
				RecipePortionLi.classList.add('combi_portion')
			} else {
				RecipePortionLi.classList.add('individual_portion')
			}
			// <h5>Use by date:</h5><p><input type="date" value="' + portion["max_date"] + '" min="' + portion["min_date"] + '"></p>
			RecipePortionLi.innerHTML = '<p><label><input type="checkbox"> ' + portion["portion_description"] + '</label></p><hr />'
			ListTopUl.appendChild(RecipePortionLi)

			whiskShoppingListPortions.push(portion["portion_description"])

		})

		showShoppingList()

		shopOnlineBlock.innerHTML = `<button id="whisk-add-products" class="list_block--collection--action">Add to online shopping list</button>`
		setupAddToWhiskShoppingListButton(whiskShoppingListPortions)
	}
	OldShoppingListContent.remove()
	ShoppingList.appendChild(ListTopUl)
	setupShoppingListCheckingOff()
}


const showShoppingList = () => {
	const html = document.querySelector('html')
	if (!html.classList.contains('shopping_list_open')) {
		html.classList.add('shopping_list_open')
	}
}

const hideShoppingList = () => {
	const html = document.querySelector('html')
	if (html.classList.contains('shopping_list_open')) {
		html.classList.remove('shopping_list_open')
	}
}

const setupShoppingListButton = () => {
	const html = document.querySelector('html')
	const toggleBtn = document.querySelector('#planner_shopping_list .list_toggle')
	toggleBtn.addEventListener("click", function(){
		html.classList.toggle('shopping_list_open')
	})
}

const setupShoppingListCheckingOff = () => {
	const shoppingListPortionsChecks = document.querySelectorAll('#planner_shopping_list .planner_sl-recipe_list li input[type="checkbox"]')
	shoppingListPortionsChecks.forEach(function(portionCheckbox){
		portionCheckbox.addEventListener("change", function(){
			const portionLi = portionCheckbox.closest('li')
			const portionId = portionLi.getAttribute('id')
			const portionType = portionLi.classList.contains('combi_portion') ? 'combi_portion' : 'individual_portion'
			// const date = portionLi.querySelector('input[type="date"]').value

			const portionData = "shopping_list_portion_id=" + portionId + "&portion_type=" + portionType
			ajaxRequest(portionData, '/stocks/add_portion')
			portionLi.style.display = 'none'
			checkForUpdates(function(shoppingListPortions) {
				renderShoppingList(shoppingListPortions)
			})
		})
	})
}


const addPlannerRecipe = (e) => {
	ajaxRequest(plannerRecipeAddData(e.item.id, e.item.parentNode.id), '/planner/recipe_add')

	const deleteBtn = document.createElement('button')
	deleteBtn.innerHTML = `<svg class="icomoon-icon icon-bin"><use xlink:href="${SVG}#icon-bin"></use></svg><img class="icon-png" src="${PNGBin}"></button>`
	deleteBtn.classList.add('delete', 'list_block--item--action', 'list_block--item--action--btn')

	const parentId = e.item.parentNode.id
	e.item.setAttribute('data-parent-id', parentId)
	e.item.classList.remove('list_block--item--with-bar')

	e.item.appendChild(deleteBtn)
	deleteBtn.addEventListener("click", function(){deletePlannerRecipe(deleteBtn)})

	checkForUpdates(function(shoppingListPortions) {
	  renderShoppingList(shoppingListPortions)
	})

}

const updatePlannerRecipe = (e) => {
	ajaxRequest(plannerRecipeUpdateData(e), '/planner/recipe_update')

	const parentId = e.item.parentNode.id
	e.item.setAttribute('data-parent-id', parentId)

	checkForUpdates(function(shoppingListPortions) {
	  renderShoppingList(shoppingListPortions)
	})
}

const deletePlannerRecipe = (deleteBtn) => {
	const buttonParent = deleteBtn.parentNode
	const dateId = buttonParent.dataset.parentId
	const recipeId = buttonParent.id
	const deleteString = "recipe_id=" + recipeId + "&date=" + dateId
	ajaxRequest(deleteString, '/planner/recipe_delete')

	buttonParent.style.display = 'none'

	checkForUpdates(function(shoppingListPortions) {
	  renderShoppingList(shoppingListPortions)
	})
}

const plannerFn = () => {
	if (document.body.classList.contains('planner_controller', 'index_page')) {
		const slider = tns({
			container: '[data-planner]',
			items: 1,
			slideBy: 1,
			startIndex: 1,
			loop: false,
			gutter: 10,
			edgePadding: 40,
			arrowKeys: true,
			swipeAngle: false,
			controlsContainer: '.tiny-controls',
			nav: false,
			responsive: {
				420: {
					items: 1
				},
				640: {
					items: 2
				},
				900: {
					items: 3
				},
				1200: {
					items: 4
				}
			}
		});

		const recipeList = document.querySelector('[data-recipe-list]')
		const plannerBlocks = document.querySelectorAll('[data-planner] .tiny-slide:not(.yesterday) .tiny-drop')
		new Sortable.create(recipeList, {
			group: {
				name: 'recipe-sharing',
				pull: 'clone',
				put: false,
			},
			sort: false,
			onEnd: function(e) {
				if (e.item.parentNode.classList.contains('tiny-drop')){
					addPlannerRecipe(e)
				}
			}
		})
		plannerBlocks.forEach(function(dayBlock){
			new Sortable.create(dayBlock, {
				group: {
					name: 'recipe-sharing',
					pull: true,
					put: true
				},
				onEnd: function(e) {
					updatePlannerRecipe(e)
				}
			})
		})

		const plannerRecipeDeleteButtons = document.querySelectorAll('.tiny-slide .list_block--item button.delete')

		plannerRecipeDeleteButtons.forEach(function(deleteBtn){
			deleteBtn.addEventListener("click", function(){deletePlannerRecipe(deleteBtn)})
		})

	}
	if (document.body.classList.contains('recipes_controller', 'index_page')) {
		const recipeAddToPlannerButtons = document.querySelectorAll('.list_block--action_row .add_recipe_to_planner')
		recipeAddToPlannerButtons.forEach(function(addBtn){
			const recipeId = addBtn.getAttribute('data-recipe-id')
			const date = addBtn.getAttribute('data-date')
			addBtn.addEventListener("click", function(){
				ajaxRequest(plannerRecipeAddData(recipeId, date), '/planner/recipe_add')
				addBtn.style.display = 'none'
				checkForUpdates(function(shoppingListPortions) {
					renderShoppingList(shoppingListPortions)
				})
				showAlert(`Recipe added to your <a href="/planner">planner</a><br />Your shopping list is now updating`)
			})
		})
	}
	if (document.body.classList.contains('recipes_controller', 'show_page')) {
		if (document.querySelector('#add_recipe_to_planner')) {
			const recipeAddToPlannerButton = document.querySelector('#add_recipe_to_planner')
			const recipeId = recipeAddToPlannerButton.getAttribute('data-recipe-id')
			const date = recipeAddToPlannerButton.getAttribute('data-date')
			recipeAddToPlannerButton.addEventListener("click", function(){
				ajaxRequest(plannerRecipeAddData(recipeId, date), '/planner/recipe_add')
				recipeAddToPlannerButton.style.display = 'none'
				checkForUpdates(function(shoppingListPortions) {
					renderShoppingList(shoppingListPortions)
				})
				showAlert(`Recipe added to your <a href="/planner">planner</a><br />Your shopping list is now updating`)
			})
		}
	}


	if (document.querySelector('#planner_shopping_list')) {
		setupShoppingListButton()
		checkForUpdates(function(shoppingListPortions) {
			renderShoppingList(shoppingListPortions)
		})
		setupViewWhiskShoppingListButton()
	}

}

ready(plannerFn)
